class UsersController < ApplicationController
  before_action :set_user, only: %i[ show edit update destroy ]
  protect_from_forgery unless: -> { request.format.json? }
  before_action :check_user, only: [:edit, :update, :destroy]

  def check_user
    @user = User.find(params[:id])
    unless current_user == @user
      respond_to do |format|
        format.html { redirect_to @user, alert: "You are not authorized to perform this action." }
        format.json { render json: { error: "You are not authorized to perform this action." }, status: :forbidden }
      end
    end
  end

  # GET /users or /users.json
  def index
    @users = User.all.map do |user|
      user.attributes.except('updated_at', 'url', 'encrypted_password', 'reset_password_token', 'reset_password_sent_at', 'remember_created_at', 'provider', 'uid').merge({
                                                                                                                                                                            posts_count: user.posts.count,
                                                                                                                                                                            comments_count: user.comments.count,
                                                                                                                                                                            boosts_count: user.boosts.count,
                                                                                                                                                                            avatar: user.avatar.attached? ? url_for(user.avatar) : nil,
                                                                                                                                                                            cover: user.cover.attached? ? url_for(user.cover) : nil
                                                                                                                                                                          })
    end
    respond_to do |format|
      format.html
      format.json { render json: @users }
    end
  end

  # GET /users/1 or /users/1.json
  def show
    user = User.find(params[:id])
    posts_count = user.posts.count
    comments_count = user.comments.count
    boosts_count = user.boosts.count

    @user_hash = user.attributes.except('updated_at', 'url', 'encrypted_password', 'reset_password_token', 'reset_password_sent_at', 'remember_created_at', 'provider', 'uid').merge({
                                                                                                                                                                                       posts_count: posts_count,
                                                                                                                                                                                       comments_count: comments_count,
                                                                                                                                                                                       boosts_count: boosts_count,
                                                                                                                                                                                       avatar: user.avatar.attached? ? url_for(user.avatar) : nil,
                                                                                                                                                                                       cover: user.cover.attached? ? url_for(user.cover) : nil
                                                                                                                                                                                     })

    @user = user
    @from_user_view = true
    prepare_comments
    @filter = params[:filter] || 'all'
    @sort = params[:sort] || 'top'
    @type = params[:type]
    @search = params[:search]

    # Change sort to 'commented' if sort is 'oldest' and filter is 'posts'
    if @sort == 'oldest' && @filter == 'posts'
      @sort = 'top'
    end

    case @filter
    when 'posts'
      @posts = sort_posts(user.posts)
      @comments = []
      @boosts = []
      @post = @posts.first unless @posts.empty?
    when 'comments'
      @posts = []
      @comments = sort_comments(user.comments)
      @boosts = []
      @post = @comments.first.post unless @comments.empty?
    when 'boosts'
      @posts = []
      @comments = []
      @boosts = user.boosts
    when 'all'
      @posts = sort_posts(user.posts)
      @comments = sort_comments(user.comments)
      @boosts = user.boosts
      @post = @posts.first unless @posts.empty?
    end

    respond_to do |format|
      format.html
      format.json { render json: @user_hash }
    end
  end
  

  # GET /users/new
  def new
    @user = User.new
  end

  # PATCH/PUT /users/1 or /users/1.json
  def update
    @user = User.find(params[:id])

    if params[:avatar]
      @user.save_image_to_s3(params[:avatar], 'avatar')
    end
    if params[:cover]
      @user.save_image_to_s3(params[:cover], 'cover')
    end

    respond_to do |format|
      if @user.update(user_params)
        user_hash = @user.attributes.except('updated_at', 'url', 'encrypted_password', 'reset_password_token', 'reset_password_sent_at', 'remember_created_at', 'provider', 'uid').merge({
                                                                                                                                                                                           posts_count: @user.posts.count,
                                                                                                                                                                                           comments_count: @user.comments.count,
                                                                                                                                                                                           boosts_count: @user.boosts.count,
                                                                                                                                                                                           avatar: @user.avatar.attached? ? url_for(@user.avatar) : nil,
                                                                                                                                                                                           cover: @user.cover.attached? ? url_for(@user.cover) : nil
                                                                                                                                                                                         })

        format.html { redirect_to @user, notice: "User was successfully updated." }
        format.json { render json: user_hash }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { error: "There was an error updating the user.", errors: @user.errors }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1 or /users/1.json
  def destroy
    if @user.destroy
      respond_to do |format|
        format.html { redirect_to users_url, notice: "User was successfully destroyed." }
        format.json { render json: { message: "User was successfully destroyed." }, status: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to users_url, alert: "There was an error destroying the user." }
        format.json { render json: { error: "There was an error destroying the user." }, status: :unprocessable_entity }
      end
    end
  end

  def logout
    sign_out current_user
    redirect_to root_path
  end

  def comments
    @user = User.find(params[:id])
    @comments = @user.comments
    @selected_filter = params[:sort] || 'top'

    case @selected_filter
    when 'top'
      @comments = @comments.left_joins(:likes_comments).group(:id).order('COUNT(likes_comments.id) DESC')
    when 'newest'
      @comments = @comments.order(created_at: :desc)
    when 'oldest'
      @comments = @comments.order(created_at: :asc)
    end

    respond_to do |format|
      format.html
      format.json { render json: @comments.as_json(except: [:updated_at],
                                                   methods: [:replies_count, :likes_count, :dislikes_count, :user_name,
                                                             :post_title]) }
    end
  end

  def posts
    @user = User.find(params[:id])
    @posts = @user.posts
    @selected_filter = params[:sort] || 'top'

    case @selected_filter
    when 'top'
      @posts = @posts.left_joins(:likes).group(:id).order('COUNT(likes.id) DESC')
    when 'commented'
      @posts = @posts.left_joins(:comments).group(:id).order('COUNT(comments.id) DESC')
    when 'newest'
      @posts = @posts.order(created_at: :desc)
    end

    respond_to do |format|
      format.html
      format.json { render json: @posts.as_json(except: [:magazine_id, :user_id, :updated_at], methods: [:comments_count, :likes_count, :dislikes_count, :boosts_count, :user_name, :magazine_name]) }
    end
  end

  def boosts
    @user = User.find(params[:id])
    @boosted_posts = @user.boosts

    respond_to do |format|
      format.html
      format.json { render json: @boosted_posts.map { |boost| boost.post.as_json(except: [:magazine_id, :user_id, :updated_at], methods: [:comments_count, :likes_count, :dislikes_count, :boosts_count, :user_name, :magazine_name]) } }
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def prepare_comments
    @comment = Comment.new
    @comments = @user.comments
  end

  # Only allow a list of trusted parameters through.
  def user_params
    params.require(:user).permit(:name, :username, :description, :avatar, :cover)
  end

  def sort_posts(posts)
    case @sort
    when 'top'
      posts.left_joins(:likes).group(:id).order('COUNT(likes.id) DESC')
    when 'commented'
      posts.left_joins(:comments).group(:id).order('COUNT(comments.id) DESC')
    when 'newest'
      posts.order(created_at: :desc)
    else
      posts
    end
  end
  
  def sort_comments(comments)
    case @sort
    when 'top'
      comments.left_joins(:likes_comments).group(:id).order('COUNT(likes_comments.id) DESC')
    when 'oldest'
      comments.order(created_at: :asc)
    when 'newest'
      comments.order(created_at: :desc)
    end
  end
end
