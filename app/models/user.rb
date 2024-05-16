class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  has_one_attached :avatar
  has_one_attached :cover
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :boosts, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_posts, through: :likes, source: :post, dependent: :destroy
  has_many :dislikes, dependent: :destroy
  has_many :disliked_posts, through: :dislikes, source: :post, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :subscribed_magazines, through: :subscriptions, source: :magazine, dependent: :destroy
  has_many :boosted_posts, through: :boosts, source: :post, dependent: :destroy
  has_many :likes_comments, dependent: :destroy
  has_many :liked_comments, through: :likes_comments, source: :comment, dependent: :destroy
  has_many :dislikes_comments, dependent: :destroy
  has_many :disliked_comments, through: :dislikes_comments, source: :comment, dependent: :destroy
  has_many :created_magazines, class_name: 'Magazine', foreign_key: 'user_id', dependent: :destroy
  devise :omniauthable, omniauth_providers: [:google_oauth2]

  after_create :generate_api_key

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

  def commented_posts
    Post.joins(:comments).where(comments: { user_id: id }).distinct
  end

  def save_image_to_s3(image, image_type)
    name = File.basename(image.path)
    s3 = Aws::S3::Resource.new(
      region: 'us-east-1',
      access_key_id: ENV['AWS_ACCESS_KEY_ID'],
      secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
      session_token: ENV['AWS_SESSION_TOKEN']
    )
    bucket = s3.bucket('tuiter-bucket') # reemplaza 'tuiter-bucket' con el nombre de tu bucket
    obj = bucket.object("#{image_type}/#{name}")
    obj.upload_file(image.path)
  end

  private

  def generate_api_key
    self.api_key = SecureRandom.hex
    save!
  end
end

