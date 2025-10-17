class AccessRequestsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_access_request, only: [:show, :edit, :update, :destroy, :resend, :cancel]

  def index
    # List all access requests with filtering and search
    @access_requests = current_user.access_requests.includes(:client, :access_template, :access_grants)
    
    # Apply filters
    @access_requests = @access_requests.where(status: params[:status]) if params[:status].present?
    @access_requests = @access_requests.joins(:client).where("clients.company ILIKE ?", "%#{params[:company]}%") if params[:company].present?
    @access_requests = @access_requests.joins(:access_template).where("access_templates.name ILIKE ?", "%#{params[:template]}%") if params[:template].present?
    
    @access_requests = @access_requests.order(created_at: :desc)
  end

  def show
    # Show request details with grant status
    @access_grants = @access_request.access_grants.includes(:integration_provider)
  end

  def new
    # Create new access request for a client
    @access_request = AccessRequest.new
    @access_templates = current_user.access_templates
    @clients = Client.all
  end

  def create
    # Create access request and generate secure link
    @access_request = AccessRequest.new(access_request_params)
    @access_request.access_template = current_user.access_templates.find(params[:access_template_id])
    
    if @access_request.save
      # Generate the secure link for the client
      @access_link = links_access_request_url(@access_request.token)
      redirect_to @access_request, notice: 'Access request was successfully created.'
    else
      @access_templates = current_user.access_templates
      @clients = Client.all
      render :new
    end
  end

  def edit
    # Edit request details (limited changes allowed)
    @access_templates = current_user.access_templates
    @clients = Client.all
  end

  def update
    # Update request details
    if @access_request.update(access_request_params)
      redirect_to @access_request, notice: 'Access request was successfully updated.'
    else
      @access_templates = current_user.access_templates
      @clients = Client.all
      render :edit
    end
  end

  def destroy
    # Cancel/delete request
    if @access_request.active?
      @access_request.update(status: 'cancelled')
      redirect_to access_requests_path, notice: 'Access request was cancelled.'
    else
      @access_request.destroy
      redirect_to access_requests_path, notice: 'Access request was deleted.'
    end
  end

  def resend
    # Regenerate token and send new link
    @access_request.regenerate_token
    @access_request.update(expires_at: 7.days.from_now)
    redirect_to @access_request, notice: 'New access link generated.'
  end

  def cancel
    # Cancel the request
    @access_request.update(status: 'cancelled')
    redirect_to @access_request, notice: 'Access request was cancelled.'
  end

  def export
    # Export requests to CSV
    @access_requests = current_user.access_requests.includes(:client, :access_template, :access_grants)
    respond_to do |format|
      format.csv { send_data generate_csv(@access_requests), filename: "access_requests_#{Date.current}.csv" }
    end
  end

  private

  def set_access_request
    @access_request = current_user.access_requests.find(params[:id])
  end

  def access_request_params
    params.require(:access_request).permit(:client_id, :expires_at)
  end

  def generate_csv(requests)
    # Generate CSV export of access requests
    CSV.generate do |csv|
      csv << ['Client', 'Template', 'Status', 'Created', 'Expires', 'Grants']
      requests.each do |request|
        csv << [
          request.client.display_name,
          request.access_template.name,
          request.status,
          request.created_at.strftime('%Y-%m-%d'),
          request.expires_at.strftime('%Y-%m-%d'),
          request.access_grants.count
        ]
      end
    end
  end
end
