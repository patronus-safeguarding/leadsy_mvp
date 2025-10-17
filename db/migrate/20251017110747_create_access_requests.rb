class CreateAccessRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :access_requests, id: :uuid do |t|
      t.references :access_template, null: false, foreign_key: true, type: :uuid
      t.references :client, null: false, foreign_key: true, type: :uuid
      t.string :token, null: false
      t.datetime :expires_at, null: false
      t.string :status, default: 'pending', null: false

      t.timestamps
    end

    add_index :access_requests, :token, unique: true
    add_index :access_requests, :status
    add_index :access_requests, :expires_at
  end
end
