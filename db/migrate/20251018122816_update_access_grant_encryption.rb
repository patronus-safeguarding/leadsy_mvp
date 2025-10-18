class UpdateAccessGrantEncryption < ActiveRecord::Migration[7.1]
  def change
    # Remove old encrypted columns
    remove_column :access_grants, :access_token_encrypted, :text
    remove_column :access_grants, :refresh_token_encrypted, :text
    
    # Add new encrypted columns using Rails built-in encryption
    add_column :access_grants, :access_token, :text
    add_column :access_grants, :refresh_token, :text
  end
end
