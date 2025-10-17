class CreateIntegrationProviders < ActiveRecord::Migration[7.1]
  def change
    create_table :integration_providers, id: :uuid do |t|
      t.string :name, null: false
      t.string :provider_type, null: false
      t.string :base_url
      t.string :client_id, null: false
      t.text :client_secret_encrypted
      t.string :oauth_authorize_url, null: false
      t.string :oauth_token_url, null: false
      t.jsonb :scopes, default: [], null: false

      t.timestamps
    end

    add_index :integration_providers, :provider_type
    add_index :integration_providers, :name
  end
end
