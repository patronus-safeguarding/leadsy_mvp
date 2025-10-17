class Providers::GrantFinalizer
  include Dry::Monads[:result]

  def call(access_request:, provider:, token_data:)
    # Idempotent operation to create or update access grant
    # Returns Success(grant) or Failure(error_message)
    
    ActiveRecord::Base.transaction do
      grant = find_or_initialize_grant(access_request, provider)
      
      # Update grant with token data
      grant.assign_attributes(
        provider_account_id: token_data[:provider_account_id],
        access_token: token_data[:access_token],
        refresh_token: token_data[:refresh_token],
        token_expires_at: calculate_expires_at(token_data[:expires_in]),
        status: 'active'
      )
      
      if grant.save
        # Update access request status if this is the first grant
        update_access_request_status(access_request)
        
        # Trigger background jobs for asset fetching
        trigger_background_jobs(grant)
        
        Success(grant)
      else
        Failure("Failed to save access grant: #{grant.errors.full_messages.join(', ')}")
      end
    end
  rescue => e
    Failure("Grant finalization failed: #{e.message}")
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
  end
end
