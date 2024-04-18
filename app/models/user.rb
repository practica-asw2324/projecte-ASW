class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
    has_many :posts
    has_many :likes
    has_many :liked_posts, through: :likes, source: :post
    has_many :dislikes
    has_many :disliked_posts, through: :dislikes, source: :post
    has_many :subscriptions
    has_many :subscribed_magazines, through: :subscriptions, source: :magazine
    has_many :boosts
    has_many :boosted_posts, through: :boosts, source: :post
    has_many :likes_comments
    has_many :liked_comments, through: :likes_comments, source: :comment
    has_many :dislikes_comments
    has_many :disliked_comments, through: :dislikes_comments, source: :comment
    has_many :created_magazines, class_name: 'Magazine', foreign_key: 'user_id'
    devise :omniauthable, omniauth_providers: [:google_oauth2]

    def liked_post?(post)
        self.liked_posts.include?(post)
    end

    def disliked_post?(post)
        self.disliked_posts.include?(post)
    end

    def boosted_post?(post)
        boosted_posts.include?(post)
    end

    def liked_comment?(comment)
        liked_comments.include?(comment)
    end

    def disliked_comment?(comment)
        disliked_comments.include?(comment)
    end

  def self.from_google(u)
    username = u[:email].split('@').first
    name = u[:name].split(' ')[0]
    create_with(uid: u[:uid], provider: 'google', email: u[:email], username: username, name: name,
                password: Devise.friendly_token[0, 20]).find_or_create_by!(email: u[:email])
  end
end

