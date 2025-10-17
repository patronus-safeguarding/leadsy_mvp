class CreateAccessGrants < ActiveRecord::Migration[7.1]
  def change
    create_table :access_grants, id: :uuid do |t|
      t.references :access_request, null: false, foreign_key: true, type: :uuid
      t.references :integration_provider, null: false, foreign_key: true, type: :uuid
      t.string :provider_account_id, null: false
      t.text :access_token_encrypted
      t.text :refresh_token_encrypted
      t.datetime :token_expires_at
      t.string :status, default: 'active', null: false
      t.jsonb :assets, default: [], null: false

      t.timestamps
    end

    add_index :access_grants, :provider_account_id
    add_index :access_grants, :status
    add_index :access_grants, [:access_request_id, :integration_provider_id], unique: true, name: 'idx_access_grants_unique_request_provider'
  end
end
