class Post < ApplicationRecord
  validates :url, :title, :body, :author, presence: true
end