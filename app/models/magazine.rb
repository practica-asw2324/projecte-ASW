class Magazine < ApplicationRecord
    has_many :posts
    belongs_to :user

    has_many :subscriptions
    has_many :users, through: :subscriptions
end