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
    @users = User.all
  end

  # GET /users/1 or /users/1.json
  def show
    @user = User.find(params[:id])
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
      @posts = sort_posts(@user.posts)
      @comments = []
      @boosts = []
      @post = @posts.first unless @posts.empty?
    when 'comments'
      @posts = []
      @comments = sort_comments(@user.comments)
      @boosts = []
      @post = @comments.first.post unless @comments.empty?
    when 'boosts'
      @posts = []
      @comments = []
      @boosts = @user.boosts
    when 'all'
      @posts = sort_posts(@user.posts)
      @comments = sort_comments(@user.comments)
      @boosts = @user.boosts
      @post = @posts.first unless @posts.empty?
    end
  end
  

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users or /users.json
  def create
    @user = User.new(user_params)
    respond_to do |format|
      if @user.save
        format.html { redirect_to user_url(@user) }
        format.json { render :show, status: :created, location: @user }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
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

    if @user.update(user_params)
      redirect_to @user
    else
      render :edit
    end
  end

  # DELETE /users/1 or /users/1.json
  def destroy
    @user.destroy

    respond_to do |format|
      format.html { redirect_to users_url }
      format.json { head :no_content }
    end
  end

  def logout
    sign_out current_user
    redirect_to root_path
  end

  private

  # Use callbacks to share common setup or constraints between actions.
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
