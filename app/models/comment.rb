class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post
  has_many :likes_comments
  has_many :likers_comments, through: :likes_comments, source: :user
  has_many :dislikes_comments
  has_many :dislikers_comments, through: :dislikes_comments, source: :user
end
