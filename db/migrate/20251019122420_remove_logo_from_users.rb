class RemoveLogoFromUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :users, :logo, :string
  end
end
