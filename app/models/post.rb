class Post < ApplicationRecord

  validates :title, presence: true
  validates :magazine, presence: true, if: :is_link?
  validates :url, presence: true, if: :is_link?
  belongs_to :user
  alias_attribute :author, :user
  belongs_to :magazine
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :likers, through: :likes, source: :user, dependent: :destroy
  has_many :dislikes, dependent: :destroy
  has_many :dislikers, through: :dislikes, source: :user, dependent: :destroy
  has_many :boosts, dependent: :destroy
  has_many :boosters, through: :boosts, source: :user, dependent: :destroy

  private
  def is_link?
    url.present?
  end

  def likes_count
    self.likes.count
  end

  def dislikes_count
    self.dislikes.count
  end

  def boosts_count
    self.boosts.count
  end

  def user_name
    self.user.name
  end

  def magazine_name
    self.magazine.name
  end

  def comments_count
    self.comments.count
  end

end