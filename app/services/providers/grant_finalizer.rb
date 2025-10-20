class Providers::GrantFinalizer
  include Dry::Monads[:result]

  def call(access_request:, provider:, token_data:)
    Rails.logger.info "=== Grant Finalization Started ==="
    Rails.logger.info "Access Request ID: #{access_request.id}"
    Rails.logger.info "Provider ID: #{provider.id}"
    Rails.logger.info "Token data keys: #{token_data.keys}"
    
    # Idempotent operation to create or update access grant
    # Returns Success(grant) or Failure(error_message)
    
    ActiveRecord::Base.transaction do
      grant = find_or_initialize_grant(access_request, provider)
      Rails.logger.info "Grant found/initialized: #{grant.persisted? ? 'EXISTING' : 'NEW'}"
      Rails.logger.info "Grant ID: #{grant.id}" if grant.persisted?
      
      # Update grant with token data
      grant.assign_attributes(
        provider_account_id: token_data[:provider_account_id],
        access_token: token_data[:access_token],
        refresh_token: token_data[:refresh_token],
        token_expires_at: calculate_expires_at(token_data[:expires_in]),
        status: 'active'
      )
      
      Rails.logger.info "Grant attributes assigned"
      Rails.logger.info "Provider Account ID: #{grant.provider_account_id}"
      Rails.logger.info "Token expires at: #{grant.token_expires_at}"
      
      if grant.save
        Rails.logger.info "Grant saved successfully with ID: #{grant.id}"
        
        # Update access request status if this is the first grant
        update_access_request_status(access_request)
        Rails.logger.info "Access request status updated"
        
        # Trigger background jobs for asset fetching
        trigger_background_jobs(grant)
        Rails.logger.info "Background jobs triggered"
        
        Rails.logger.info "=== Grant Finalization Completed Successfully ==="
        Success(grant)
      else
        error_message = "Failed to save access grant: #{grant.errors.full_messages.join(', ')}"
        Rails.logger.error "=== Grant Finalization Failed ==="
        Rails.logger.error error_message
        Rails.logger.error "Grant errors: #{grant.errors.full_messages}"
        Failure(error_message)
      end
    end
  rescue => e
    error_message = "Grant finalization failed: #{e.message}"
    Rails.logger.error "=== Grant Finalization Exception ==="
    Rails.logger.error error_message
    Rails.logger.error e.backtrace.join("\n")
    Failure(error_message)
  end

  private

  def find_or_initialize_grant(access_request, provider)
    AccessGrant.find_or_initialize_by(
      access_request: access_request,
      integration_provider: provider
    )
  end

  def calculate_expires_at(expires_in)
    return nil unless expires_in
    
    Time.current + expires_in.seconds
  end

  def update_access_request_status(access_request)
    # Update request status to approved if this is the first grant
    if access_request.pending?
      access_request.update(status: 'approved')
    end
  end

  def trigger_background_jobs(grant)
    # Queue background jobs for token exchange and asset fetching
    TokenExchangeJob.perform_later(grant.id)
    FetchAssetsJob.perform_later(grant.id)
    InviteUserToGrantedAccountsJob.perform_later(grant.id)
  end
end
