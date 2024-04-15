class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post
  has_many :likes_comments, dependent: :destroy
  has_many :likers_comments, through: :likes_comments, source: :user
  has_many :dislikes_comments, dependent: :destroy
  has_many :dislikers_comments, through: :dislikes_comments, source: :user
  belongs_to :parent, class_name: 'Comment', foreign_key: 'comment_id', optional: true
  has_many :replies, class_name: 'Comment', foreign_key: 'comment_id', dependent: :destroy

  def depth
    parent ? parent.depth + 1 : 0
  end

end
