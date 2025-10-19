class Providers::OauthController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:meta_callback, :google_callback]
  before_action :set_access_request_from_state, only: [:meta_callback, :google_callback]
  before_action :set_access_request_from_token, only: [:meta_redirect, :google_redirect]

  def meta_redirect
    # Redirect client to Meta OAuth authorization
    provider = IntegrationProvider.meta.first
    state = generate_state_token(params[:token])
    
    redirect_to build_oauth_url(provider, state), allow_other_host: true
  end

  def google_redirect
    # Redirect client to Google OAuth authorization
    provider = IntegrationProvider.google.first
    state = generate_state_token(params[:token])
    
    redirect_to build_oauth_url(provider, state), allow_other_host: true
  end

  def meta_callback
    # Handle Meta OAuth callback
    handle_oauth_callback('meta')
  end

  def google_callback
    # Handle Google OAuth callback
    handle_oauth_callback('google')
  end

  private

  def set_access_request_from_state
    @access_request = AccessRequest.by_token(extract_token_from_state(params[:state])).first
    redirect_to root_path, alert: 'Invalid state parameter.' unless @access_request
  end

  def set_access_request_from_token
    @access_request = AccessRequest.by_token(params[:token]).first
    redirect_to root_path, alert: 'Invalid access token.' unless @access_request
  end

  def handle_oauth_callback(provider_type)
    Rails.logger.info "=== OAuth Callback Started ==="
    Rails.logger.info "Provider: #{provider_type}"
    Rails.logger.info "Access Request ID: #{@access_request&.id}"
    Rails.logger.info "Access Request Token: #{@access_request&.token}"
    Rails.logger.info "OAuth Code: #{params[:code]&.first(20)}..." if params[:code]
    Rails.logger.info "State: #{params[:state]&.first(50)}..." if params[:state]
    
    provider = IntegrationProvider.find_by(provider_type: provider_type)
    Rails.logger.info "Provider found: #{provider.present?}"
    Rails.logger.info "Provider ID: #{provider&.id}" if provider
    
    service = "Providers::#{provider_type.camelize}::Oauth".constantize.new
    Rails.logger.info "OAuth service initialized: #{service.class.name}"
    
    Rails.logger.info "Starting token exchange..."
    result = service.exchange_code_for_token(params[:code], provider)
    Rails.logger.info "Token exchange result: #{result.success? ? 'SUCCESS' : 'FAILURE'}"
    
    if result.success?
      Rails.logger.info "Token data received: #{result.value!.keys}"
      Rails.logger.info "Starting grant finalization..."
      
      # Create access grant
      grant_finalizer = Providers::GrantFinalizer.new
      grant_result = grant_finalizer.call(
        access_request: @access_request,
        provider: provider,
        token_data: result.value!
      )
      
      Rails.logger.info "Grant finalization result: #{grant_result.success? ? 'SUCCESS' : 'FAILURE'}"
      
      if grant_result.success?
        Rails.logger.info "Access grant created successfully: #{grant_result.value!.id}"
        redirect_to links_access_request_path(@access_request.token),
                    notice: "#{provider.display_name} access granted successfully!"
      else
        Rails.logger.error "Grant finalization failed: #{grant_result.failure}"
        redirect_to links_access_request_path(@access_request.token),
                    alert: "Failed to grant access: #{grant_result.failure}"
      end
    else
      Rails.logger.error "Token exchange failed: #{result.failure}"
      redirect_to links_access_request_path(@access_request.token),
                  alert: "OAuth authorization failed: #{result.failure}"
    end
    
    Rails.logger.info "=== OAuth Callback Completed ==="
  end

  def generate_state_token(access_token)
    # Create signed state parameter with access request token
    Rails.application.message_verifier(:oauth_state).generate(access_token)
  end

  def extract_token_from_state(state)
    Rails.application.message_verifier(:oauth_state).verify(state)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end

  def build_oauth_url(provider, state)
    # Build OAuth authorization URL with proper scopes
    scopes = @access_request.access_template.provider_scopes_for(provider.provider_type)
    
    "#{provider.oauth_authorize_url}?" + {
      client_id: provider.client_id,
      redirect_uri: callback_url(provider.provider_type),
      scope: scopes.join(','),
      response_type: 'code',
      state: state
    }.to_query
  end

  def callback_url(provider_type)
    case provider_type
    when 'meta'
      meta_callback_providers_oauth_index_url
    when 'google'
      google_callback_providers_oauth_index_url
    end
  end
end
