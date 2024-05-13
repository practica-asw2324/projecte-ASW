class Magazine < ApplicationRecord
    has_many :posts
    belongs_to :user

    has_many :subscriptions
    has_many :users, through: :subscriptions

    validates :name, presence: true, uniqueness: { message: "This value has already been used." }
    validates :title, presence: true

    def posts_count
        self.posts.count
    end

    def comments_count
        self.posts.sum { |post| post.comments.count }
    end

    def subscribers_count
        self.users.count
    end
end