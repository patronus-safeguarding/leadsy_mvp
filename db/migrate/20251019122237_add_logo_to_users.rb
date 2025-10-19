class AddLogoToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :logo, :string
  end
end
