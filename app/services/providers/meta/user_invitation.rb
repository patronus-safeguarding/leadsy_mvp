class Providers::Meta::UserInvitation
  include Dry::Monads[:result]

  def initialize(access_grant)
    @access_grant = access_grant
    @access_token = access_grant.access_token
  end

  def invite_user_to_business_account(email:, business_account_id:, role: 'ADMIN')
    Rails.logger.info "=== Meta User Invitation Started ==="
    Rails.logger.info "Email: #{email}"
    Rails.logger.info "Business Account ID: #{business_account_id}"
    Rails.logger.info "Role: #{role}"

    begin
      # First, get the business account details to verify access
      business_account = get_business_account(business_account_id)
      return Failure("Business account not found or no access") unless business_account

      Rails.logger.info "Business account found: #{business_account['name']}"

      # Invite user to the business account
      invitation_result = send_invitation(email, business_account_id, role)
      
      if invitation_result.success?
        Rails.logger.info "=== Meta User Invitation Completed Successfully ==="
        Success({
          invitation_id: invitation_result.value!['id'],
          business_account_name: business_account['name'],
          email: email,
          role: role
        })
      else
        Rails.logger.error "=== Meta User Invitation Failed ==="
        Rails.logger.error "Error: #{invitation_result.failure}"
        Failure(invitation_result.failure)
      end
    rescue => e
      error_message = "Meta user invitation error: #{e.message}"
      Rails.logger.error "=== Meta User Invitation Exception ==="
      Rails.logger.error error_message
      Rails.logger.error e.backtrace.join("\n")
      Failure(error_message)
    end
  end

  def get_business_accounts
    Rails.logger.info "=== Fetching Meta Business Accounts ==="
    
    begin
      uri = URI("https://graph.facebook.com/v18.0/me/businesses")
      uri.query = URI.encode_www_form({
        access_token: @access_token,
        fields: 'id,name,primary_page'
      })

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      request = Net::HTTP::Get.new(uri)

      Rails.logger.info "Making request to: #{uri}"
      response = http.request(request)
      Rails.logger.info "Response code: #{response.code}"
      Rails.logger.info "Response body: #{response.body}"

      if response.code == '200'
        data = JSON.parse(response.body)
        Rails.logger.info "Found #{data['data']&.length || 0} business accounts"
        Rails.logger.info "Business accounts data: #{data}"
        Success(data['data'] || [])
      else
        error_data = JSON.parse(response.body) rescue { error: response.body }
        error_message = "Failed to fetch business accounts: #{error_data['error']['message'] rescue response.body}"
        Rails.logger.error error_message
        Rails.logger.error "Full error response: #{response.body}"
        Failure(error_message)
      end
    rescue => e
      error_message = "Error fetching business accounts: #{e.message}"
      Rails.logger.error error_message
      Failure(error_message)
    end
  end

  private

  def get_business_account(business_account_id)
    uri = URI("https://graph.facebook.com/v18.0/#{business_account_id}")
    uri.query = URI.encode_www_form({
      access_token: @access_token,
      fields: 'id,name,primary_page'
    })

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri)

    response = http.request(request)
    
    if response.code == '200'
      JSON.parse(response.body)
    else
      nil
    end
  end

  def send_invitation(email, business_account_id, role)
    Rails.logger.info "Sending invitation to #{email} for business account #{business_account_id}"

    uri = URI("https://graph.facebook.com/v18.0/#{business_account_id}/user_invitations")
    
    params = {
      email: email,
      role: role,
      access_token: @access_token
    }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri)
    request.set_form_data(params)

    Rails.logger.info "Making invitation request to: #{uri}"
    Rails.logger.info "Params: #{params.except(:access_token).merge(access_token: '[FILTERED]')}"
    
    response = http.request(request)
    Rails.logger.info "Response code: #{response.code}"
    Rails.logger.info "Response body: #{response.body}"

    if response.code == '200'
      data = JSON.parse(response.body)
      Rails.logger.info "Invitation sent successfully: #{data['id']}"
      Success(data)
    else
      error_data = JSON.parse(response.body) rescue { error: response.body }
      error_message = "Failed to send invitation: #{error_data['error']['message'] rescue response.body}"
      Rails.logger.error error_message
      Failure(error_message)
    end
  end
end
