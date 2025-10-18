require 'net/http'
require 'uri'
require 'json'

class FetchAssetsJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :exponentially_longer, attempts: 3

  def perform(access_grant_id)
    grant = AccessGrant.find(access_grant_id)
    
    # Fetch available assets (pages, ad accounts, etc.) for the grant
    # This returns a list of accessible resources
    
    case grant.integration_provider.provider_type
    when 'meta'
      fetch_meta_assets(grant)
    when 'google'
      fetch_google_assets(grant)
    else
      Rails.logger.warn "Unknown provider type: #{grant.integration_provider.provider_type}"
    end
  end

  private

  def fetch_meta_assets(grant)
    Rails.logger.info "Fetching Meta assets for grant #{grant.id}"
    
    begin
      # Test API connection and fetch user's pages and ad accounts
      assets = []
      
      # Fetch user's pages
      pages = fetch_meta_pages(grant.access_token)
      assets.concat(pages) if pages
      
      # Fetch user's ad accounts
      ad_accounts = fetch_meta_ad_accounts(grant.access_token)
      assets.concat(ad_accounts) if ad_accounts
      
      # Update grant with fetched assets
      grant.update(assets: assets)
      
      Rails.logger.info "Fetched #{assets.count} Meta assets for grant #{grant.id}"
      
    rescue => e
      Rails.logger.error "Failed to fetch Meta assets for grant #{grant.id}: #{e.message}"
      # Update with empty assets array to indicate the attempt was made
      grant.update(assets: [])
    end
  end
  
  private
  
  def fetch_meta_pages(access_token)
    # Fetch user's Facebook pages
    uri = URI('https://graph.facebook.com/me/accounts')
    params = {
      access_token: access_token,
      fields: 'id,name,category,access_token'
    }
    uri.query = URI.encode_www_form(params)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri)
    
    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      pages = data['data'] || []
      pages.map do |page|
        {
          id: page['id'],
          name: page['name'],
          type: 'page',
          category: page['category'],
          permissions: ['ADVERTISE', 'MANAGE'],
          access_token: page['access_token'] ? 'available' : 'none'
        }
      end
    else
      Rails.logger.warn "Failed to fetch Meta pages: HTTP #{response.code}"
      []
    end
  rescue => e
    Rails.logger.warn "Error fetching Meta pages: #{e.message}"
    []
  end
  
  def fetch_meta_ad_accounts(access_token)
    # Fetch user's ad accounts
    uri = URI('https://graph.facebook.com/me/adaccounts')
    params = {
      access_token: access_token,
      fields: 'id,name,account_status,currency'
    }
    uri.query = URI.encode_www_form(params)
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri)
    
    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      accounts = data['data'] || []
      accounts.map do |account|
        {
          id: account['id'],
          name: account['name'],
          type: 'ad_account',
          status: account['account_status'],
          currency: account['currency'],
          permissions: ['MANAGE', 'VIEW']
        }
      end
    else
      Rails.logger.warn "Failed to fetch Meta ad accounts: HTTP #{response.code}"
      []
    end
  rescue => e
    Rails.logger.warn "Error fetching Meta ad accounts: #{e.message}"
    []
  end

  def fetch_google_assets(grant)
    Rails.logger.info "Fetching Google assets for grant #{grant.id}"
    
    begin
      # Test API connection and fetch user's Google Ads accounts
      assets = []
      
      # Fetch user's Google Ads customers (accounts)
      customers = fetch_google_customers(grant.access_token)
      assets.concat(customers) if customers
      
      # Update grant with fetched assets
      grant.update(assets: assets)
      
      Rails.logger.info "Fetched #{assets.count} Google assets for grant #{grant.id}"
      
    rescue => e
      Rails.logger.error "Failed to fetch Google assets for grant #{grant.id}: #{e.message}"
      # Update with empty assets array to indicate the attempt was made
      grant.update(assets: [])
    end
  end
  
  def fetch_google_customers(access_token)
    # Fetch user's Google Ads customers
    uri = URI('https://googleads.googleapis.com/v16/customers:listAccessibleCustomers')
    
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{access_token}"
    request['developer-token'] = Rails.application.credentials.google_ads_developer_token rescue 'test_token'
    
    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      resource_names = data['resourceNames'] || []
      resource_names.map do |resource_name|
        # Extract customer ID from resource name
        customer_id = resource_name.split('/').last
        {
          id: customer_id,
          name: "Google Ads Customer #{customer_id}",
          type: 'customer',
          resource_name: resource_name,
          permissions: ['READ', 'WRITE']
        }
      end
    else
      Rails.logger.warn "Failed to fetch Google customers: HTTP #{response.code}"
      []
    end
  rescue => e
    Rails.logger.warn "Error fetching Google customers: #{e.message}"
    []
  end
end
