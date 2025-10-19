class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    # Get all clients for the current user
    @clients = current_user.clients.order(:name)
    
    # Get all access templates for the current user
    @access_templates = current_user.access_templates.order(:name)
    
    # Get selected client or default to first client
    @selected_client = params[:client_id] ? @clients.find(params[:client_id]) : @clients.first
    
    # Get selected template (default to first template if none selected)
    if params[:template_id].present?
      @selected_template = @access_templates.find(params[:template_id])
    elsif @access_templates.any?
      @selected_template = @access_templates.first
      # Redirect to include the template_id parameter for consistency
      redirect_to dashboard_path(client_id: @selected_client&.id, template_id: @selected_template.id) and return
    else
      @selected_template = nil
    end
    
    # Get client-specific data
    if @selected_client
      # Filter access requests by selected template if one is selected
      if @selected_template
        @client_requests = @selected_client.access_requests.where(access_template: @selected_template).includes(:access_template, :access_grants).recent.limit(5)
        @client_grants = @selected_client.access_grants.joins(:access_request).where(access_requests: { access_template: @selected_template }).includes(:integration_provider)
      else
        @client_requests = []
        @client_grants = []
      end
      
      # Show generated link if it was just created
      @access_link = params[:generated_link]
    else
      @access_link = nil
      @client_requests = []
      @client_grants = []
    end
    
    # Overall dashboard stats
    @total_requests = current_user.access_requests.count
    @total_grants = current_user.access_requests.joins(:access_grants).count
    @active_clients = current_user.access_requests.joins(:client).distinct.count(:client_id)
  end

  def generate_link
    client = current_user.clients.find(params[:client_id])
    template = current_user.access_templates.find(params[:template_id])
    
    access_request = AccessRequest.create!(
      client: client,
      access_template: template,
      expires_at: 7.days.from_now
    )
    
    # Generate the public client-facing link
    if Rails.env.development?
      access_link = links_access_request_url(access_request.token)
    else
      access_link = links_access_request_url(access_request.token, host: 'leadsy-mvp-15e02325b037.herokuapp.com', protocol: 'https')
    end
    
    redirect_to dashboard_path(client_id: client.id, template_id: template.id, generated_link: access_link)
  end

  private

  def generate_access_link(client, template)
    # Generate client-facing access request links
    # Always create a new access request for each link generation
    
    if template
      # Always create a new access request
      access_request = AccessRequest.create!(
        client: client,
        access_template: template,
        expires_at: 7.days.from_now
      )
      
      # Generate the public client-facing link
      if Rails.env.development?
        links_access_request_url(access_request.token)
      else
        links_access_request_url(access_request.token, host: 'leadsy-mvp-15e02325b037.herokuapp.com', protocol: 'https')
      end
    else
      nil # Return nil instead of "#" to indicate no template exists
    end
  end
end
