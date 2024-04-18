class RemoveNullToMagazineCreatedAt < ActiveRecord::Migration[7.0]
  def change
    change_column_null :magazines, :updated_at, true
  end
end
