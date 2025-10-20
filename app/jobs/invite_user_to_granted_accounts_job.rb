class InviteUserToGrantedAccountsJob < ApplicationJob
  queue_as :default

  # Invites the access template's owner (current agency user) to all allowed accounts
  # for the given provider grant. Uses provider-specific invitation services.
  def perform(access_grant_id)
    access_grant = AccessGrant.find_by(id: access_grant_id)
    return unless access_grant&.active?

    access_request = access_grant.access_request
    template_owner = access_request.access_template.user
    user_email = template_owner&.email
    return unless user_email.present?

    provider_type = access_grant.integration_provider.provider_type

    case provider_type
    when 'google'
      invite_google_accounts(access_grant, user_email)
    when 'meta'
      invite_meta_businesses(access_grant, user_email)
    else
      Rails.logger.info "InviteUserToGrantedAccountsJob: No invitation implementation for provider_type=#{provider_type}"
    end
  end

  private

  def invite_google_accounts(access_grant, email)
    inviter = Providers::Google::UserInvitation.new(access_grant)
    customers_result = inviter.get_accessible_customers
    return unless customers_result.success?

    customers = customers_result.value!
    customers.each do |customer|
      customer_id = customer['id'] || customer['customer']&.dig('id') || customer['resource_name']&.split('/')&.last
      next unless customer_id.present?

      inviter.invite_user_to_account(email: email, customer_id: customer_id, role: 'STANDARD')
    end
  end

  def invite_meta_businesses(access_grant, email)
    inviter = Providers::Meta::UserInvitation.new(access_grant)
    businesses_result = inviter.get_business_accounts
    return unless businesses_result.success?

    businesses = businesses_result.value!
    businesses.each do |business|
      business_id = business['id']
      next unless business_id.present?

      inviter.invite_user_to_business_account(email: email, business_account_id: business_id, role: 'ADMIN')
    end
  end
end


