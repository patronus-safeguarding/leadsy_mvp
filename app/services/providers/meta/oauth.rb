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
    uri = URI('https://graph.facebook.com/v18.0/oauth/access_token')
    
    params = {
      client_id: provider.client_id,
      client_secret: provider.client_secret,
      redirect_uri: callback_url,
      code: code
    }
    
    uri.query = URI.encode_www_form(params)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri)
    
    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      
      # Get user info to create a proper provider_account_id
      user_info = get_user_info(data['access_token'])
      
      Success({
        access_token: data['access_token'],
        refresh_token: nil, # Meta doesn't use refresh tokens
        expires_in: data['expires_in'] || 3600,
        provider_account_id: user_info[:user_id] || "meta_user_#{SecureRandom.hex(8)}"
      })
    else
      error_data = JSON.parse(response.body) rescue { error: response.body }
      Failure("Meta token exchange failed: #{error_data['error']['message'] rescue response.body}")
    end
  rescue => e
    Failure("Meta token exchange error: #{e.message}")
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
    Rails.application.routes.url_helpers.meta_callback_providers_oauth_index_url(
      host: Rails.application.routes.default_url_options[:host],
      port: Rails.application.routes.default_url_options[:port]
    )
  end
end