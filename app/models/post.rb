class Post < ApplicationRecord
  validates :url, :title, :body, :author, presence: true
  belongs_to :user
  alias_attribute :author, :user
  belongs_to :magazine
  has_many :comments
  has_many :likes
  has_many :likers, through: :likes, source: :user
  has_many :dislikes
  has_many :dislikers, through: :dislikes, source: :user
  has_many :boosts
  has_many :boosters, through: :boosts, source: :user

end