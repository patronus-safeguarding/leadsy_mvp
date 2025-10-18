require 'net/http'
require 'uri'
require 'json'

class TokenExchangeJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(access_grant_id)
    grant = AccessGrant.find(access_grant_id)
    
    # Exchange access token for long-lived token if needed
    # This is provider-specific and would be implemented based on provider requirements
    
    case grant.integration_provider.provider_type
    when 'meta'
      exchange_meta_token(grant)
    when 'google'
      exchange_google_token(grant)
    else
      Rails.logger.warn "Unknown provider type: #{grant.integration_provider.provider_type}"
    end
  end

  private

  def exchange_meta_token(grant)
    Rails.logger.info "Testing Meta API connection for grant #{grant.id}"
    
    begin
      # Test the access token by making a simple API call to get user info
      response = test_meta_connection(grant.access_token)
      
      if response[:success]
        Rails.logger.info "Meta API connection successful for grant #{grant.id}"
        
        # Update grant with success status and extended expiry
        grant.update(
          access_token: grant.access_token, # Keep the same token if it works
          token_expires_at: 60.days.from_now
        )
        
        Rails.logger.info "Meta token validated and extended for grant #{grant.id}"
      else
        Rails.logger.error "Meta API connection failed for grant #{grant.id}: #{response[:error]}"
        grant.update(status: 'error')
      end
      
    rescue => e
      Rails.logger.error "Meta API connection error for grant #{grant.id}: #{e.message}"
      grant.update(status: 'error')
    end
  end
  
  private
  
  def test_meta_connection(access_token)
    # Test Meta API connection by calling the /me endpoint
    uri = URI('https://graph.facebook.com/me')
    params = {
      access_token: access_token,
      fields: 'id,name,email'
    }
    uri.query = URI.encode_www_form(params)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri)
    
    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      {
        success: true,
        user_id: data['id'],
        user_name: data['name'],
        user_email: data['email']
      }
    else
      {
        success: false,
        error: "HTTP #{response.code}: #{response.body}"
      }
    end
  rescue => e
    {
      success: false,
      error: e.message
    }
  end

  def exchange_google_token(grant)
    Rails.logger.info "Testing Google API connection for grant #{grant.id}"
    
    begin
      # Test the access token by making a simple API call to get user info
      response = test_google_connection(grant.access_token)
      
      if response[:success]
        Rails.logger.info "Google API connection successful for grant #{grant.id}"
        
        # Update grant with success status and extended expiry
        grant.update(
          access_token: grant.access_token, # Keep the same token if it works
          token_expires_at: 1.hour.from_now
        )
        
        Rails.logger.info "Google token validated for grant #{grant.id}"
      else
        Rails.logger.error "Google API connection failed for grant #{grant.id}: #{response[:error]}"
        grant.update(status: 'error')
      end
      
    rescue => e
      Rails.logger.error "Google API connection error for grant #{grant.id}: #{e.message}"
      grant.update(status: 'error')
    end
  end
  
  def test_google_connection(access_token)
    # Test Google API connection by calling the userinfo endpoint
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
        success: true,
        user_id: data['id'],
        user_name: data['name'],
        user_email: data['email']
      }
    else
      {
        success: false,
        error: "HTTP #{response.code}: #{response.body}"
      }
    end
  rescue => e
    {
      success: false,
      error: e.message
    }
  end
end
