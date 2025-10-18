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
    provider = IntegrationProvider.find_by(provider_type: provider_type)
    service = "Providers::#{provider_type.camelize}::Oauth".constantize.new
    
    result = service.exchange_code_for_token(params[:code], provider)

    if result.success?
      # Create access grant
      grant_finalizer = Providers::GrantFinalizer.new
      grant_result = grant_finalizer.call(
        access_request: @access_request,
        provider: provider,
        token_data: result.value!
      )

      if grant_result.success?
        redirect_to links_access_request_path(@access_request.token),
                    notice: "#{provider.display_name} access granted successfully!"
      else
        redirect_to links_access_request_path(@access_request.token),
                    alert: "Failed to grant access: #{grant_result.failure}"
      end
    else
      redirect_to links_access_request_path(@access_request.token),
                  alert: "OAuth authorization failed: #{result.failure}"
    end
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
