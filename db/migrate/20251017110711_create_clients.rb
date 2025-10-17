class CreateClients < ActiveRecord::Migration[7.1]
  def change
    create_table :clients, id: :uuid do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :company
      t.string :phone

      t.timestamps
    end

    add_index :clients, :email
    add_index :clients, :company
  end
end
