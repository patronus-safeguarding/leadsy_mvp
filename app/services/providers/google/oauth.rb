require 'net/http'
require 'uri'
require 'json'

class Providers::Google::Oauth < Providers::BaseOauth
  def exchange_code_for_token(code, provider)
    # Google-specific OAuth token exchange - make real API call
    if code.present? && provider.present?
      make_token_exchange_request(code, provider)
    else
      Failure("Invalid Google OAuth code or provider")
    end
  end

  def refresh_access_token(refresh_token, provider)
    # Google-specific token refresh
    if refresh_token.present? && provider.present?
      make_refresh_token_request(refresh_token, provider)
    else
      Failure("Invalid Google refresh token or provider")
    end
  end

  def revoke_access_token(access_token, provider)
    # Google-specific token revocation
    if access_token.present? && provider.present?
      make_revoke_token_request(access_token)
    else
      Failure("Invalid Google access token or provider")
    end
  end

  private
  
  def make_token_exchange_request(code, provider)
    uri = URI('https://oauth2.googleapis.com/token')
    
    params = {
      client_id: provider.client_id,
      client_secret: provider.client_secret,
      code: code,
      grant_type: 'authorization_code',
      redirect_uri: callback_url
    }
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/x-www-form-urlencoded'
    request.body = URI.encode_www_form(params)
    
    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      
      # Get user info to create a proper provider_account_id
      user_info = get_user_info(data['access_token'])
      
      Success({
        access_token: data['access_token'],
        refresh_token: data['refresh_token'],
        expires_in: data['expires_in'] || 3600,
        provider_account_id: user_info[:user_id] || "google_user_#{SecureRandom.hex(8)}"
      })
    else
      error_data = JSON.parse(response.body) rescue { error: response.body }
      Failure("Google token exchange failed: #{error_data['error_description'] || response.body}")
    end
  rescue => e
    Failure("Google token exchange error: #{e.message}")
  end
  
  def make_refresh_token_request(refresh_token, provider)
    uri = URI('https://oauth2.googleapis.com/token')
    
    params = {
      client_id: provider.client_id,
      client_secret: provider.client_secret,
      refresh_token: refresh_token,
      grant_type: 'refresh_token'
    }
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri)
    request['Content-Type'] = 'application/x-www-form-urlencoded'
    request.body = URI.encode_www_form(params)
    
    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      Success({
        access_token: data['access_token'],
        expires_in: data['expires_in'] || 3600
      })
    else
      error_data = JSON.parse(response.body) rescue { error: response.body }
      Failure("Google token refresh failed: #{error_data['error_description'] || response.body}")
    end
  rescue => e
    Failure("Google token refresh error: #{e.message}")
  end
  
  def make_revoke_token_request(access_token)
    uri = URI('https://oauth2.googleapis.com/revoke')
    params = { token: access_token }
    uri.query = URI.encode_www_form(params)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri)
    
    response = http.request(request)
    
    if response.code == '200'
      Success(true)
    else
      Failure("Google token revocation failed: #{response.body}")
    end
  rescue => e
    Failure("Google token revocation error: #{e.message}")
  end
  
  def get_user_info(access_token)
    uri = URI('https://www.googleapis.com/oauth2/v2/userinfo')
    params = { access_token: access_token }
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
    Rails.logger.warn "Failed to get Google user info: #{e.message}"
    { user_id: nil, user_name: nil }
  end

  def build_token_request_params(code, provider)
    {
      client_id: provider.client_id,
      client_secret: provider.client_secret,
      code: code,
      grant_type: 'authorization_code',
      redirect_uri: callback_url
    }
  end

  def callback_url
    Rails.application.routes.url_helpers.google_callback_providers_oauth_index_url(
      host: Rails.application.routes.default_url_options[:host],
      port: Rails.application.routes.default_url_options[:port]
    )
  end
end