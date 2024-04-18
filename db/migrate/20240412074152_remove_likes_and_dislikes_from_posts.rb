class RemoveLikesAndDislikesFromPosts < ActiveRecord::Migration[7.0]
  def change
    remove_column :posts, :likes, :integer
    remove_column :posts, :dislikes, :integer
  end
end
