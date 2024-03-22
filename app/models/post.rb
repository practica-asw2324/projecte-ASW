class Post < ApplicationRecord
  validates :url, :title, :body, presence: true
end
