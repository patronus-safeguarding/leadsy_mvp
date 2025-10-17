class CreateAuditEvents < ActiveRecord::Migration[7.1]
  def change
    create_table :audit_events, id: :uuid do |t|
      t.references :auditable, polymorphic: true, null: false, type: :uuid
      t.string :action, null: false
      t.jsonb :audit_changes, default: {}, null: false
      t.references :user, null: false, foreign_key: true, type: :uuid

      t.timestamps
    end

    add_index :audit_events, [:auditable_type, :auditable_id]
    add_index :audit_events, :action
    add_index :audit_events, :created_at
  end
end
