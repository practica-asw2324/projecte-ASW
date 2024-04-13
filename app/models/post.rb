class Post < ApplicationRecord
  validates :url, :title, :body, :author, presence: true
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
end