class User < ApplicationRecord
    has_many :posts
    has_many :likes
    has_many :liked_posts, through: :likes, source: :post
    has_many :dislikes
    has_many :disliked_posts, through: :dislikes, source: :post

    def liked_post?(post)
        self.liked_posts.include?(post)
    end

    def disliked_post?(post)
        self.disliked_posts.include?(post)
    end
end

