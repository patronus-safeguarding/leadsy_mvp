class UpdateAuditEventActionEnum < ActiveRecord::Migration[7.1]
  def up
    # Update existing enum values to avoid conflicts with Active Record methods
    execute "UPDATE audit_events SET action = 'create_action' WHERE action = 'create'"
    execute "UPDATE audit_events SET action = 'update_action' WHERE action = 'update'"
    execute "UPDATE audit_events SET action = 'delete_action' WHERE action = 'destroy'"
    execute "UPDATE audit_events SET action = 'approve_action' WHERE action = 'approve'"
    execute "UPDATE audit_events SET action = 'revoke_action' WHERE action = 'revoke'"
  end

  def down
    # Revert the changes
    execute "UPDATE audit_events SET action = 'create' WHERE action = 'create_action'"
    execute "UPDATE audit_events SET action = 'update' WHERE action = 'update_action'"
    execute "UPDATE audit_events SET action = 'destroy' WHERE action = 'delete_action'"
    execute "UPDATE audit_events SET action = 'approve' WHERE action = 'approve_action'"
    execute "UPDATE audit_events SET action = 'revoke' WHERE action = 'revoke_action'"
  end
end
