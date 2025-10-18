require 'net/http'
require 'uri'
require 'json'

class ApiTestController < ApplicationController
  before_action :authenticate_user!
  
  def test_meta
    grant = AccessGrant.find(params[:grant_id])
    
    if grant.integration_provider.provider_type == 'meta'
      result = test_meta_api(grant.access_token)
      render json: result
    else
      render json: { error: 'Grant is not for Meta provider' }, status: 400
    end
  end
  
  def test_google
    grant = AccessGrant.find(params[:grant_id])
    
    if grant.integration_provider.provider_type == 'google'
      result = test_google_api(grant.access_token)
      render json: result
    else
      render json: { error: 'Grant is not for Google provider' }, status: 400
    end
  end
  
  private
  
  def test_meta_api(access_token)
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
        provider: 'Meta',
        user_id: data['id'],
        user_name: data['name'],
        user_email: data['email'],
        status: 'Connected'
      }
    else
      {
        success: false,
        provider: 'Meta',
        error: "HTTP #{response.code}: #{response.body}",
        status: 'Failed'
      }
    end
  rescue => e
    {
      success: false,
      provider: 'Meta',
      error: e.message,
      status: 'Error'
    }
  end
  
  def test_google_api(access_token)
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
        provider: 'Google',
        user_id: data['id'],
        user_name: data['name'],
        user_email: data['email'],
        status: 'Connected'
      }
    else
      {
        success: false,
        provider: 'Google',
        error: "HTTP #{response.code}: #{response.body}",
        status: 'Failed'
      }
    end
  rescue => e
    {
      success: false,
      provider: 'Google',
      error: e.message,
      status: 'Error'
    }
  end
end
