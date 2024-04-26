class PostsController < ApplicationController
  before_action :authenticate_user, only: [:new, :create, :like, :dislike, :boost]
  before_action :set_post, only: %i[ show edit update destroy like dislike sort_comments ]
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
  end

  # PUT /posts/:id/boost
  def boost
    @post = Post.find(params[:id])
    user = current_user
  
    respond_to do |format|
      # If the user has already boosted the post, remove the boost
      if user.boosted_post?(@post)
        @post.boosts.find_by(user: user).destroy
        format.html { redirect_back(fallback_location: root_path, notice: "You've unboosted this post.") }
        format.json { render json: { boosts_count: @post.boosts.count, message: "You've unboosted this post." } }
      else
        # If the user hasn't boosted the post yet, create a new boost
        @post.boosts.create(user: user)
        format.html { redirect_back(fallback_location: root_path, notice: "You've boosted this post.") }
        format.json { render json: { boosts_count: @post.boosts.count, message: "You've boosted this post." } }
      end
    end
  end

  # GET /posts/1 or /posts/1.json
  def show
    prepare_comments
  end

  # PUT /posts/:id/like
  def like
    @like = @post.likes.find_or_initialize_by(user: current_user)
  
    respond_to do |format|
      if @like.persisted?
        @like.destroy
        format.html { redirect_back(fallback_location: root_path, notice: "You've unliked this post.") }
        format.json { render json: { likes_count: @post.likes.count, message: "You've unliked this post." } }
      else
        # If the user has disliked the post, remove the dislike
        if current_user.disliked_post?(@post)
          @post.dislikes.find_by(user: current_user).destroy
        end
  
        if @like.save
          format.html { redirect_back(fallback_location: root_path, notice: "You've liked this post.") }
          format.json { render json: { likes_count: @post.likes.count, message: "You've liked this post." } }
        else
          format.html { redirect_back(fallback_location: root_path, alert: "There was an error liking this post.") }
          format.json { render json: { error: "There was an error liking this post." }, status: :unprocessable_entity }
        end
      end
    end
  end

  # PUT /posts/:id/dislike
  def dislike
    @dislike = @post.dislikes.find_or_initialize_by(user: current_user)

    respond_to do |format|
      if @dislike.persisted?
        @dislike.destroy
        format.html { redirect_back(fallback_location: root_path, notice: "You've removed your dislike for this post.") }
        format.json { render json: { dislikes_count: @post.dislikes.count, message: "You've removed your dislike for this post." } }
      else
        # If the user has liked the post, remove the like
        if current_user.liked_post?(@post)
          @post.likes.find_by(user: current_user).destroy
        end

        if @dislike.save
          format.html { redirect_back(fallback_location: root_path, notice: "You've disliked this post.") }
          format.json { render json: { dislikes_count: @post.dislikes.count, message: "You've disliked this post." } }
        else
          format.html { redirect_back(fallback_location: root_path, alert: "There was an error disliking this post.") }
          format.json { render json: { error: "There was an error disliking this post." }, status: :unprocessable_entity }
        end
      end
    end
  end

  # GET /posts/new
  def new
    @post = Post.new
    @is_link = params[:type] == 'link'
    @magazines = Magazine.all
  end

  # POST /posts or /posts.json
  def create
    user = current_user
  
    @post = Post.new(post_params)
    @post.user_id = user.id
    @is_link = params[:type] == 'link'
  
    respond_to do |format|
      if @post.save
        format.html { redirect_to root_path, notice: 'Post was successfully created.' }
        format.json { render json: @post, status: :created }
      else
        format.html { render :new }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /posts/1/edit
  def edit
    @post = Post.find(params[:id])
    @is_link = !@post.url.nil?
    @magazines = Magazine.all
  end

  # PATCH/PUT /posts/1 or /posts/1.json
  def update
    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to post_url(@post), notice: "Post was successfully updated." }
        format.json { render json: { message: "Post was successfully updated.", post: @post }, status: :ok }
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
        format.json { render json: { message: "Post was successfully destroyed." }, status: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to posts_url, alert: "There was an error destroying the post." }
        format.json { render json: { error: "There was an error destroying the post." }, status: :unprocessable_entity }
      end
    end
  end

  def sort_comments
    prepare_comments
    render 'show'
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

  def prepare_comments
    @comment = Comment.new
    @comments = @post.comments.where(comment_id: nil)
    @selected_filter = params[:sort] || 'top'
    case @selected_filter
    when 'top'
      @comments = @comments.left_joins(:likes_comments)
                           .group('comments.id')
                           .order('COUNT(likes_comments.id) DESC')
    when 'newest'
      @comments = @comments.order(created_at: :desc)
    when 'old'
      @comments = @comments.order(created_at: :asc)
    else
      @comments = @comments.order(created_at: :desc)
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
