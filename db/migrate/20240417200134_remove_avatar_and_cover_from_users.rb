class RemoveAvatarAndCoverFromUsers < ActiveRecord::Migration[6.0]
  def change
    remove_column :users, :avatar
    remove_column :users, :cover
  end
end