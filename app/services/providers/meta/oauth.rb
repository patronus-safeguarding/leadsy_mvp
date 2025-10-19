require 'net/http'
require 'uri'
require 'json'

class Providers::Meta::Oauth < Providers::BaseOauth
  def exchange_code_for_token(code, provider)
    # Meta-specific OAuth token exchange - make real API call
    if code.present? && provider.present?
      make_token_exchange_request(code, provider)
    else
      Failure("Invalid Meta OAuth code or provider")
    end
  end
  
  def refresh_access_token(refresh_token, provider)
    # Meta doesn't support refresh tokens - return failure
    Failure("Meta doesn't support token refresh")
  end

  def revoke_access_token(access_token, provider)
    # Meta-specific token revocation
    if access_token.present? && provider.present?
      # In production, call Meta's revocation endpoint
      Success(true)
    else
      Failure("Invalid Meta access token or provider")
    end
  end

  private
  
  def make_token_exchange_request(code, provider)
    Rails.logger.info "=== Meta Token Exchange Started ==="
    Rails.logger.info "Provider ID: #{provider.id}"
    Rails.logger.info "Client ID: #{provider.client_id}"
    Rails.logger.info "Code: #{code&.first(20)}..."
    
    uri = URI('https://graph.facebook.com/v18.0/oauth/access_token')
    
    params = {
      client_id: provider.client_id,
      client_secret: provider.client_secret,
      redirect_uri: callback_url,
      code: code
    }
    
    Rails.logger.info "Callback URL: #{callback_url}"
    Rails.logger.info "Request params: #{params.except(:client_secret, :code).merge(code: '[FILTERED]', client_secret: '[FILTERED]')}"
    
    uri.query = URI.encode_www_form(params)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri)
    
    Rails.logger.info "Making request to: #{uri}"
    response = http.request(request)
    Rails.logger.info "Response code: #{response.code}"
    Rails.logger.info "Response body: #{response.body}"
    
    if response.code == '200'
      data = JSON.parse(response.body)
      Rails.logger.info "Token exchange successful, getting user info..."
      
      # Get user info to create a proper provider_account_id
      user_info = get_user_info(data['access_token'])
      Rails.logger.info "User info: #{user_info}"
      
      token_data = {
        access_token: data['access_token'],
        refresh_token: nil, # Meta doesn't use refresh tokens
        expires_in: data['expires_in'] || 3600,
        provider_account_id: user_info[:user_id] || "meta_user_#{SecureRandom.hex(8)}"
      }
      
      Rails.logger.info "Token data prepared: #{token_data.except(:access_token).merge(access_token: '[FILTERED]')}"
      Rails.logger.info "=== Meta Token Exchange Completed Successfully ==="
      
      Success(token_data)
    else
      error_data = JSON.parse(response.body) rescue { error: response.body }
      error_message = "Meta token exchange failed: #{error_data['error']['message'] rescue response.body}"
      Rails.logger.error "=== Meta Token Exchange Failed ==="
      Rails.logger.error error_message
      Failure(error_message)
    end
  rescue => e
    error_message = "Meta token exchange error: #{e.message}"
    Rails.logger.error "=== Meta Token Exchange Exception ==="
    Rails.logger.error error_message
    Rails.logger.error e.backtrace.join("\n")
    Failure(error_message)
  end
  
  def get_user_info(access_token)
    uri = URI('https://graph.facebook.com/me')
    params = {
      access_token: access_token,
      fields: 'id,name'
    }
    uri.query = URI.encode_www_form(params)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri)
    
    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      {
        user_id: data['id'],
        user_name: data['name']
      }
    else
      { user_id: nil, user_name: nil }
    end
  rescue => e
    Rails.logger.warn "Failed to get user info: #{e.message}"
    { user_id: nil, user_name: nil }
  end

  def build_token_request_params(code, provider)
    {
      client_id: provider.client_id,
      client_secret: provider.client_secret,
      code: code,
      redirect_uri: callback_url
    }
  end

  def callback_url
    # Use the same callback URL generation as the controller
    Rails.application.routes.url_helpers.meta_callback_providers_oauth_index_url
  end
end