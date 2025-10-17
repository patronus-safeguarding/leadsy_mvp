class AuditEvent < ApplicationRecord
  # Associations
  belongs_to :auditable, polymorphic: true
  belongs_to :user

  # Enums
  enum :action, {
    create: 'create',
    update: 'update',
    destroy: 'destroy',
    approve: 'approve',
    revoke: 'revoke'
  }

  # Validations
  validates :action, presence: true
  validates :audit_changes, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :by_auditable, ->(auditable) { where(auditable: auditable) }
  scope :by_action, ->(action) { where(action: action) }

  # Methods
  def auditable_name
    case auditable_type
    when 'AccessRequest'
      "Access Request for #{auditable.client.display_name}"
    when 'AccessGrant'
      "#{auditable.integration_provider.display_name} Grant"
    when 'AccessTemplate'
      "Template: #{auditable.name}"
    else
      "#{auditable_type} ##{auditable_id}"
    end
  end
end
