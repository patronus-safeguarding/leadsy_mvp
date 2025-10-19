class UserInvitationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_access_grant, only: [:show, :business_accounts, :invite_user]

  def show
    @business_accounts = []
    @invitation_result = nil
    @error_message = nil
  end

  def business_accounts
    invitation_service = Providers::Meta::UserInvitation.new(@access_grant)
    result = invitation_service.get_business_accounts

    if result.success?
      @business_accounts = result.value!
      render json: { business_accounts: @business_accounts }
    else
      render json: { error: result.failure }, status: :unprocessable_entity
    end
  end

  def invite_user
    email = params[:email]
    business_account_id = params[:business_account_id]
    role = params[:role] || 'ADMIN'

    if email.blank? || business_account_id.blank?
      render json: { error: 'Email and business account ID are required' }, status: :bad_request
      return
    end

    invitation_service = Providers::Meta::UserInvitation.new(@access_grant)
    result = invitation_service.invite_user_to_business_account(
      email: email,
      business_account_id: business_account_id,
      role: role
    )

    if result.success?
      invitation_data = result.value!
      render json: { 
        success: true, 
        message: "User invitation sent successfully to #{email}",
        invitation: invitation_data
      }
    else
      render json: { error: result.failure }, status: :unprocessable_entity
    end
  end

  private

  def set_access_grant
    @access_grant = AccessGrant.find(params[:id])
    
    unless @access_grant.active? && !@access_grant.token_expired?
      redirect_to access_grants_path, alert: 'Access grant is not active or has expired'
    end
  end
end
