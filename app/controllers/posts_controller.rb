class PostsController < ApplicationController
  before_action :authenticate_user, only: [:new, :create, :like, :unlike, :undislike, :dislike, :boost, :unboost]
  before_action :set_post, only: %i[ show edit update destroy like unlike dislike undislike sort_comments boost unboost]
  protect_from_forgery unless: -> { request.format.json? }
  before_action :check_user, only: [:edit, :update, :destroy]

  # GET /posts or /posts.json
  def index
      params[:sort] ||= 'newest'
      params[:type] ||= 'all'

      if params[:search]
        session[:last_search] = params[:search]
        @posts = Post.where("lower(posts.title) LIKE ? OR lower(posts.body) LIKE ?", "%#{params[:search].downcase}%", "%#{params[:search].downcase}%")
      else
        @posts = Post.includes(:user, :magazine, :comments)
      end

      case params[:sort]
      when 'top'
        @posts = @posts.left_joins(:likes).group(:id).order('COUNT(likes.id) DESC')
      when 'commented'
        @posts = @posts.left_joins(:comments).group(:id).order('COUNT(comments.id) DESC')
      when 'newest'
        @posts = @posts.order(created_at: :desc)
      end
    
      case params[:type]
      when 'links'
        @posts = @posts.where.not(url: [nil, ''])
      when 'threads'
        @posts = @posts.where(url: [nil, ''])
      end

      @posts.each do |post|
        post.current_user_likes = current_user
        post.current_user_dislikes = current_user
        post.current_user_boosts = current_user
      end

      respond_to do |format|
        format.html
        format.json { render json: @posts.as_json(except: [:updated_at], methods: [:comments_count, :likes_count, :dislikes_count, :boosts_count, :user_name, :magazine_name, :current_user_likes, :current_user_dislikes, :current_user_boosts]) }      end
  end

  # GET /posts/1 or /posts/1.json
  def show
    @post = Post.find(params[:id])
    @post.current_user_likes = current_user
    @post.current_user_dislikes = current_user
    @post.current_user_boosts = current_user
    @comments = @post.comments.where(comment_id: nil)
    @selected_filter = params[:sort] || 'top'
    @comments = @comments.sort_comments(@selected_filter)
    respond_to do |format|
      format.html
      format.json { render json: @post.as_json(except: [:updated_at], methods: [:comments_count, :likes_count, :dislikes_count, :boosts_count, :user_name, :magazine_name, :current_user_likes, :current_user_dislikes, :current_user_boosts]) }
    end
  end

  # POST /posts/:id/boost
  # POST /posts/:id/boost
def boost
  @boost = @post.boosts.find_or_initialize_by(user: current_user)
  already_boosted = !@boost.new_record?

  respond_to do |format|
    if @boost.save
      format.html { redirect_back(fallback_location: root_path, notice: "You've boosted this post.") }
      format.json do
        if already_boosted
          render json: { error: "You've already boosted this post." }, status: :conflict
        else
          @post.current_user_likes = current_user
          @post.current_user_dislikes = current_user
          @post.current_user_boosts = current_user
          render json: @post.as_json(except: [:updated_at], methods: [:comments_count, :likes_count, :dislikes_count, :boosts_count, :user_name, :magazine_name, :current_user_likes, :current_user_dislikes, :current_user_boosts])
        end
      end
    else
      format.html { redirect_back(fallback_location: root_path, alert: "There was an error boosting this post.") }
      format.json { render json: { error: "There was an error boosting this post." }, status: :unprocessable_entity }
    end
  end
rescue => e
  respond_to do |format|
    format.html { redirect_back(fallback_location: root_path, notice: "An error occurred: #{e.message}") }
    format.json { render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error }
  end
end
  
  # DELETE /posts/:id/boost
  def unboost
    @boost = @post.boosts.find_by(user: current_user)
  
    respond_to do |format|
      if @boost&.destroy
        @post.current_user_likes = current_user
        @post.current_user_dislikes = current_user
        @post.current_user_boosts = current_user
        format.html { redirect_back(fallback_location: root_path, notice: "You've unboosted this post.") }
        format.json { render json: @post.as_json(except: [:updated_at], methods: [:comments_count, :likes_count, :dislikes_count, :boosts_count, :user_name, :magazine_name, :current_user_likes, :current_user_dislikes, :current_user_boosts]) }
      else
        format.html { redirect_back(fallback_location: root_path, alert: "Unable to unboost this post.") }
        format.json { render json: { error: "Unable to unboost this post." }, status: :unprocessable_entity }
      end
    end
  rescue => e
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path, notice: "An error occurred: #{e.message}") }
      format.json { render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error }
    end
  end

  # POST /posts/:id/like
  def like
    @like = @post.likes.find_or_initialize_by(user: current_user)
    already_liked = !@like.new_record?
  
    respond_to do |format|
      # If the user has disliked the post, remove the dislike
      if current_user.disliked_post?(@post)
        @post.dislikes.find_by(user: current_user).destroy
      end
  
      if @like.save
        format.html { redirect_back(fallback_location: root_path, notice: "You've liked this post.") }
        format.json do
          if already_liked
            render json: { error: "You've already liked this post." }, status: :conflict
          else
            @post.current_user_likes = current_user
            @post.current_user_dislikes = current_user
            @post.current_user_boosts = current_user
            render json: @post.as_json(except: [:updated_at], methods: [:comments_count, :likes_count, :dislikes_count, :boosts_count, :user_name, :magazine_name, :current_user_likes, :current_user_dislikes, :current_user_boosts])
          end
        end
      else
        format.html { redirect_back(fallback_location: root_path, notice: "Unable to like this post.") }
        format.json { render json: { error: "Unable to like this post." }, status: :unprocessable_entity }
      end
    end
  rescue => e
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path, notice: "An error occurred: #{e.message}") }
      format.json { render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error }
    end
  end

  # DELETE /posts/:id/like
  def unlike
    @like = @post.likes.find_by(user: current_user)
  
    respond_to do |format|
      if @like&.destroy
        @post.current_user_likes = current_user
        @post.current_user_dislikes = current_user
        @post.current_user_boosts = current_user
        format.html { redirect_back(fallback_location: root_path, notice: "You've unliked this post.") }
        format.json { render json: @post.as_json(except: [:updated_at], methods: [:comments_count, :likes_count, :dislikes_count, :boosts_count, :user_name, :magazine_name, :current_user_likes, :current_user_dislikes, :current_user_boosts]) }
      else
        format.html { redirect_back(fallback_location: root_path, notice: "Unable to unlike this post.") }
        format.json { render json: { error: "Unable to unlike this post." }, status: :unprocessable_entity }
      end
    end
  rescue => e
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path, notice: "An error occurred: #{e.message}") }
      format.json { render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error }
    end
  end


  # POST /posts/:id/dislike
  def dislike
    @dislike = @post.dislikes.find_or_initialize_by(user: current_user)
    already_disliked = !@dislike.new_record?
  
    respond_to do |format|
      # If the user has liked the post, remove the like
      if current_user.liked_post?(@post)
        @post.likes.find_by(user: current_user).destroy
      end
  
      if @dislike.save
        format.html { redirect_back(fallback_location: root_path, notice: "You've disliked this post.") }
        format.json do
          if already_disliked
            render json: { error: "You've already disliked this post." }, status: :conflict
          else
            @post.current_user_likes = current_user
            @post.current_user_dislikes = current_user
            @post.current_user_boosts = current_user
            render json: @post.as_json(except: [:updated_at], methods: [:comments_count, :likes_count, :dislikes_count, :boosts_count, :user_name, :magazine_name, :current_user_likes, :current_user_dislikes, :current_user_boosts])
          end
        end
      else
        format.html { redirect_back(fallback_location: root_path, alert: "There was an error disliking this post.") }
        format.json { render json: { error: "There was an error disliking this post." }, status: :unprocessable_entity }
      end
    end
  rescue => e
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path, notice: "An error occurred: #{e.message}") }
      format.json { render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error }
    end
  end
  
  # DELETE /posts/:id/dislike
  def undislike
    @dislike = @post.dislikes.find_by(user: current_user)
  
    respond_to do |format|
      if @dislike&.destroy
        @post.current_user_likes = current_user
        @post.current_user_dislikes = current_user
        @post.current_user_boosts = current_user
        format.html { redirect_back(fallback_location: root_path, notice: "You've removed your dislike for this post.") }
        format.json { render json: @post.as_json(except: [:updated_at], methods: [:comments_count, :likes_count, :dislikes_count, :boosts_count, :user_name, :magazine_name, :current_user_likes, :current_user_dislikes, :current_user_boosts]) }
      else
        format.html { redirect_back(fallback_location: root_path, alert: "Unable to remove your dislike for this post.") }
        format.json { render json: { error: "Unable to remove your dislike for this post." }, status: :unprocessable_entity }
      end
    end
  rescue => e
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path, notice: "An error occurred: #{e.message}") }
      format.json { render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error }
    end
  end

  # POST /posts or /posts.json
  def create
    user = current_user
  
    @post = Post.new(post_params)
    @post.user_id = user.id
    @is_link = params[:type] == 'link'
  
    respond_to do |format|
      if @post.save
        @post.current_user_likes = current_user
        @post.current_user_dislikes = current_user
        @post.current_user_boosts = current_user
        format.html { redirect_to root_path, notice: 'Post was successfully created.' }
        format.json { render json: @post.as_json(except: [:magazine_id, :user_id, :updated_at], methods: [:comments_count, :likes_count, :dislikes_count, :boosts_count, :user_name, :magazine_name, :current_user_likes, :current_user_dislikes, :current_user_boosts]), status: :created }
      else
        format.html { render :new }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /posts/1 or /posts/1.json
  def update
    respond_to do |format|
      if @post.update(post_params)
        @post.current_user_likes = current_user
        @post.current_user_dislikes = current_user
        @post.current_user_boosts = current_user
        format.html { redirect_to post_url(@post), notice: "Post was successfully updated." }
        format.json { render json: @post.as_json(except: [:magazine_id, :user_id, :updated_at], methods: [:comments_count, :likes_count, :dislikes_count, :boosts_count, :user_name, :magazine_name, :current_user_likes, :current_user_dislikes, :current_user_boosts]) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { error: "There was an error updating the post.", errors: @post.errors }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1 or /posts/1.json
  def destroy
    if @post.destroy
      respond_to do |format|
        format.html { redirect_to posts_url, notice: "Post was successfully destroyed." }
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to posts_url, alert: "There was an error destroying the post." }
        format.json { render json: { error: "There was an error destroying the post." }, status: :unprocessable_entity }
      end
    end
  end

  # GET /posts/1/edit
  def edit
    @post = Post.find(params[:id])
    @is_link = !@post.url.nil?
    @magazines = Magazine.all
  end

  # GET /posts/new
  def new
    @post = Post.new
    @is_link = params[:type] == 'link'
    @magazines = Magazine.all
  end

  private

  def check_user
    @post = Post.find(params[:id])
    unless current_user == @post.user
      respond_to do |format|
        format.html { redirect_to @post, alert: "You are not authorized to perform this action." }
        format.json { render json: { error: "You are not authorized to perform this action." }, status: :forbidden }
      end
    end
  end

  def set_post
    @post = Post.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:title, :url, :body, :magazine_id)
  end

  def nested_comments(comments)
    comments_arr = []
    comments.each do |comment|
      comments_arr << comment
      comments_arr << nested_comments(comment.replies)
    end
    comments_arr.flatten
  end

end
