class RemoveNull < ActiveRecord::Migration[7.0]
  def change
    change_column_null :comments, :updated_at, true
  end
end
