class AddUserIdToClients < ActiveRecord::Migration[7.1]
  def up
    # First add the column as nullable
    add_reference :clients, :user, null: true, foreign_key: true, type: :uuid
    
    # Assign existing clients to the first user (if any exists)
    if User.exists?
      first_user = User.first
      Client.where(user_id: nil).update_all(user_id: first_user.id)
    end
    
    # Now make the column non-nullable
    change_column_null :clients, :user_id, false
  end
  
  def down
    remove_reference :clients, :user, foreign_key: true
  end
end
