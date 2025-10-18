class AddUserIdToAccessTemplates < ActiveRecord::Migration[7.1]
  def change
    add_reference :access_templates, :user, null: false, foreign_key: true, type: :uuid
  end
end
