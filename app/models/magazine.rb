class Magazine < ApplicationRecord
    has_many :posts
    belongs_to :user

    has_many :subscriptions
    has_many :users, through: :subscriptions

    validates :name, presence: true, uniqueness: { message: "This value has already been used." }
    validates :title, presence: true
end