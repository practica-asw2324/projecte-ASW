class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :post
  has_many :likes_comments, dependent: :destroy
  has_many :likers_comments, through: :likes_comments, source: :user
  has_many :dislikes_comments, dependent: :destroy
  has_many :dislikers_comments, through: :dislikes_comments, source: :user
  belongs_to :parent, class_name: 'Comment', foreign_key: 'comment_id', optional: true
  has_many :replies, class_name: 'Comment', foreign_key: 'comment_id', dependent: :destroy

  def liked_by?(user)
    likers_comments.include?(user)
  end

  def disliked_by?(user)
    dislikers_comments.include?(user)
  end

  def owned_by?(user)
    user == self.user
  end

  def depth
    parent ? parent.depth + 1 : 0
  end

  def likes_count
    self.likes_comments.count
  end

  def dislikes_count
    self.dislikes_comments.count
  end

  def user_name
    self.user.name
  end

  def post_title
    self.post.title
  end

  def replies_count
    self.replies.count
  end

  def all_replies
    replies.map do |reply|
      reply.as_json(except: [:updated_at],
                    methods: [:replies_count, :likes_count, :dislikes_count, :user_name,
                              :post_title, :all_replies])
    end
  end

  def self.sort_comments(sort_order)
    case sort_order
    when 'top'
      left_joins(:likes_comments)
        .group('comments.id')
        .order('COUNT(likes_comments.id) DESC')
    when 'newest'
      order(created_at: :desc)
    when 'old'
      order(created_at: :asc)
    else
      order(created_at: :desc)
    end
  end


end
