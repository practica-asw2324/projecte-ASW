class Post < ApplicationRecord

  validates :title, presence: true, length: { minimum: 2, maximum: 255,
                                              too_short: "Title must have at least 2 characters",
                                              too_long: "Title must have at most 255 characters"}
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

end