class AddCosasToPost < ActiveRecord::Migration[7.0]
  def change
    add_reference :posts, :magazine, null: false, foreign_key: true
    add_reference :posts, :user, null: false, foreign_key: true
  end
end
