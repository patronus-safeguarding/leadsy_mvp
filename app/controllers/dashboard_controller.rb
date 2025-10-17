class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    # Dashboard overview with recent activity and stats
    @recent_requests = current_user.access_requests.includes(:client, :access_template).recent.limit(10)
    @pending_requests = current_user.access_requests.pending.includes(:client, :access_template)
    @total_grants = current_user.access_requests.joins(:access_grants).count
    @active_clients = current_user.access_requests.joins(:client).distinct.count(:client_id)
    
    # Recent audit events for activity feed
    @recent_activity = AuditEvent.where(auditable: current_user.access_requests.includes(:access_grants)).recent.limit(20)
  end
end
