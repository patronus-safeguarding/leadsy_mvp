require 'net/http'
require 'uri'
require 'json'

class Providers::Google::UserInvitation
  include Dry::Monads[:result]

  def initialize(access_grant)
    @access_grant = access_grant
    @access_token = access_grant.access_token
    @developer_token = Rails.application.credentials.dig(:google_ads, :developer_token)
  end

  def invite_user_to_account(email:, customer_id:, role: 'STANDARD')
    Rails.logger.info "=== Google Ads User Invitation Started ==="
    Rails.logger.info "Email: #{email}"
    Rails.logger.info "Customer ID: #{customer_id}"
    Rails.logger.info "Role: #{role}"

    begin
      # First, verify we have access to the customer account
      customer_info = get_customer_info(customer_id)
      return Failure("Customer account not found or no access") unless customer_info

      Rails.logger.info "Customer account found: #{customer_info['descriptiveName']}"

      # Invite user to the customer account
      invitation_result = send_invitation(email, customer_id, role)
      
      if invitation_result.success?
        Rails.logger.info "=== Google Ads User Invitation Completed Successfully ==="
        Success({
          invitation_id: invitation_result.value!['results']&.first&.dig('resourceName'),
          customer_name: customer_info['descriptiveName'],
          email: email,
          role: role
        })
      else
        Rails.logger.error "=== Google Ads User Invitation Failed ==="
        Rails.logger.error "Error: #{invitation_result.failure}"
        Failure(invitation_result.failure)
      end
    rescue => e
      error_message = "Google Ads user invitation error: #{e.message}"
      Rails.logger.error "=== Google Ads User Invitation Exception ==="
      Rails.logger.error error_message
      Rails.logger.error e.backtrace.join("\n")
      Failure(error_message)
    end
  end

  def get_accessible_customers
    Rails.logger.info "=== Fetching Google Ads Accessible Customers ==="
    
    begin
      uri = URI("https://googleads.googleapis.com/v16/customers:listAccessibleCustomers")
      
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri)
      request['Authorization'] = "Bearer #{@access_token}"
      request['developer-token'] = @developer_token if @developer_token

      Rails.logger.info "Making request to: #{uri}"
      response = http.request(request)
      Rails.logger.info "Response code: #{response.code}"
      Rails.logger.info "Response body: #{response.body}"

      if response.code == '200'
        data = JSON.parse(response.body)
        customer_ids = data['resourceNames'] || []
        Rails.logger.info "Found #{customer_ids.length} accessible customers"
        
        # Get detailed info for each customer
        customers = customer_ids.map do |resource_name|
          customer_id = resource_name.split('/').last
          get_customer_info(customer_id)
        end.compact

        Success(customers)
      else
        error_data = JSON.parse(response.body) rescue { error: response.body }
        error_message = "Failed to fetch accessible customers: #{error_data['error']['message'] rescue response.body}"
        Rails.logger.error error_message
        Failure(error_message)
      end
    rescue => e
      error_message = "Error fetching accessible customers: #{e.message}"
      Rails.logger.error error_message
      Failure(error_message)
    end
  end

  private

  def get_customer_info(customer_id)
    uri = URI("https://googleads.googleapis.com/v16/customers/#{customer_id}")
    uri.query = URI.encode_www_form({
      'query' => 'SELECT customer.id, customer.descriptive_name, customer.currency_code, customer.time_zone'
    })

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri)
    request['Authorization'] = "Bearer #{@access_token}"
    request['developer-token'] = @developer_token if @developer_token

    response = http.request(request)
    
    if response.code == '200'
      data = JSON.parse(response.body)
      results = data['results'] || []
      return results.first if results.any?
    end
    
    nil
  end

  def send_invitation(email, customer_id, role)
    Rails.logger.info "Sending invitation to #{email} for customer #{customer_id}"

    uri = URI("https://googleads.googleapis.com/v16/customers/#{customer_id}/customerUsers:mutate")
    
    # Map role to Google Ads access role
    access_role = map_role_to_google_ads_role(role)
    
    request_body = {
      operations: [{
        create: {
          emailAddress: email,
          accessRole: access_role
        }
      }]
    }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri)
    request['Authorization'] = "Bearer #{@access_token}"
    request['developer-token'] = @developer_token if @developer_token
    request['Content-Type'] = 'application/json'
    request.body = request_body.to_json

    Rails.logger.info "Making invitation request to: #{uri}"
    Rails.logger.info "Request body: #{request_body.to_json}"
    
    response = http.request(request)
    Rails.logger.info "Response code: #{response.code}"
    Rails.logger.info "Response body: #{response.body}"

    if response.code == '200'
      data = JSON.parse(response.body)
      Rails.logger.info "Invitation sent successfully"
      Success(data)
    else
      error_data = JSON.parse(response.body) rescue { error: response.body }
      error_message = "Failed to send invitation: #{error_data['error']['message'] rescue response.body}"
      Rails.logger.error error_message
      Failure(error_message)
    end
  end

  def map_role_to_google_ads_role(role)
    case role.upcase
    when 'ADMIN'
      'ADMIN'
    when 'STANDARD'
      'STANDARD'
    when 'READ_ONLY'
      'READ_ONLY'
    when 'EMAIL_ONLY'
      'EMAIL_ONLY'
    else
      'STANDARD' # Default to standard access
    end
  end
end
