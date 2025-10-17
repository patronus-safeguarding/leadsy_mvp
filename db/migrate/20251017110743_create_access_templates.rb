class CreateAccessTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :access_templates, id: :uuid do |t|
      t.string :name, null: false
      t.text :description
      t.jsonb :provider_scopes, default: {}, null: false

      t.timestamps
    end

    add_index :access_templates, :name
  end
end
