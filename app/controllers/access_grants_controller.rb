class AccessGrantsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_access_grant, only: [:show, :revoke, :refresh]

  def index
    # Show all access grants for the current user's access requests
    @access_grants = AccessGrant.joins(access_request: :access_template)
                                .where(access_templates: { user_id: current_user.id })
                                .includes(:access_request, :integration_provider, access_request: [:client, :access_template])
                                .order(created_at: :desc)
    
    # Group by status for better organization
    @active_grants = @access_grants.active
    @expired_grants = @access_grants.expired
    @revoked_grants = @access_grants.revoked
  end

  def show
    # Individual access grant details
    @access_request = @access_grant.access_request
    @client = @access_request.client
    @template = @access_request.access_template
    @provider = @access_grant.integration_provider
  end

  def revoke
    if @access_grant.update(status: 'revoked')
      redirect_to access_grants_path, notice: 'Access grant revoked successfully.'
    else
      redirect_to access_grants_path, alert: 'Failed to revoke access grant.'
    end
  end

  def refresh
    # Trigger token refresh job
    TokenExchangeJob.perform_later(@access_grant.id)
    redirect_to access_grant_path(@access_grant), notice: 'Token refresh initiated.'
  end

  private

  def set_access_grant
    @access_grant = AccessGrant.joins(access_request: :access_template)
                              .where(access_templates: { user_id: current_user.id })
                              .find(params[:id])
  end
end
