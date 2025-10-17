class Links::AccessRequestsController < ApplicationController
  before_action :set_access_request_by_token
  before_action :check_request_validity

  def show
    # Public page for client to approve access
    @integration_providers = IntegrationProvider.where(provider_type: @access_request.access_template.available_providers)
  end

  def approve
    # Client approves the access request
    if @access_request.update(status: 'approved')
      redirect_to links_access_request_path(@access_request.token), 
                  notice: 'Access request approved. You can now authorize with the providers.'
    else
      redirect_to links_access_request_path(@access_request.token), 
                  alert: 'Failed to approve access request.'
    end
  end

  private

  def set_access_request_by_token
    @access_request = AccessRequest.by_token(params[:token]).first
    redirect_to root_path, alert: 'Invalid access link.' unless @access_request
  end

  def check_request_validity
    unless @access_request.can_be_accessed?
      redirect_to root_path, alert: 'This access link has expired or is no longer valid.'
    end
  end
end
