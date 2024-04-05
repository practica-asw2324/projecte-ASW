class Post < ApplicationRecord
  validates :url, :title, :body, :author, presence: true
  belongs_to :user
  belongs_to :magazine
  has_many :comments
end