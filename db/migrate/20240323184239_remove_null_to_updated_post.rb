class RemoveNullToUpdatedPost < ActiveRecord::Migration[7.0]
  def change
    change_column_null :posts, :updated_at, true
    change_column_null :users, :updated_at, true
  end
end
