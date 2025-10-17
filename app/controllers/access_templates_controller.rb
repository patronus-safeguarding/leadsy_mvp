class AccessTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_access_template, only: [:show, :edit, :update, :destroy, :duplicate]

  def index
    # List all templates for current user with search and filtering
    @access_templates = current_user.access_templates.includes(:access_requests)
    @access_templates = @access_templates.where("name ILIKE ?", "%#{params[:search]}%") if params[:search].present?
  end

  def show
    # Show template details with usage statistics
    @access_requests = @access_template.access_requests.includes(:client, :access_grants)
  end

  def new
    # Form to create new access template
    @access_template = current_user.access_templates.build
    @integration_providers = IntegrationProvider.all
  end

  def create
    # Create new access template with provider scopes
    @access_template = current_user.access_templates.build(access_template_params)
    if @access_template.save
      redirect_to @access_template, notice: 'Access template was successfully created.'
    else
      @integration_providers = IntegrationProvider.all
      render :new
    end
  end

  def edit
    # Edit existing template
    @integration_providers = IntegrationProvider.all
  end

  def update
    # Update template with new scopes
    if @access_template.update(access_template_params)
      redirect_to @access_template, notice: 'Access template was successfully updated.'
    else
      @integration_providers = IntegrationProvider.all
      render :edit
    end
  end

  def destroy
    # Delete template (only if no active requests)
    if @access_template.access_requests.active.any?
      redirect_to access_templates_path, alert: 'Cannot delete template with active requests.'
    else
      @access_template.destroy
      redirect_to access_templates_path, notice: 'Access template was successfully deleted.'
    end
  end

  def duplicate
    # Duplicate existing template
    new_template = @access_template.dup
    new_template.name = "#{@access_template.name} (Copy)"
    if new_template.save
      redirect_to new_template, notice: 'Access template was successfully duplicated.'
    else
      redirect_to @access_template, alert: 'Failed to duplicate template.'
    end
  end

  private

  def set_access_template
    @access_template = current_user.access_templates.find(params[:id])
  end

  def access_template_params
    params.require(:access_template).permit(:name, :description, provider_scopes: {})
  end
end
