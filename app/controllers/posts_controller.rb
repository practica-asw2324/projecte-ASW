class PostsController < ApplicationController
  before_action :authenticate_user, only: [:new, :create, :like, :dislike, :boost]
  before_action :set_post, only: %i[ show edit update destroy like sort_comments ]

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

    # If the user has already boosted the post, remove the boost
    if user.boosted_post?(@post)
      @post.boosts.find_by(user: user).destroy
      flash[:notice] = "You've unboosted this post."
    else
      # If the user hasn't boosted the post yet, create a new boost
      @post.boosts.create(user: user)
      flash[:notice] = "You've boosted this post."
    end

    redirect_back(fallback_location: root_path)
  end

  # GET /posts/1 or /posts/1.json
  def show
    prepare_comments
  end

  # POST /posts/:id/react
  def react
    @post = Post.find(params[:id])
  end

  # PUT /posts/:id/like
  def like
    @post = Post.find(params[:id])

    # If the user has already liked the post, remove the like
    if current_user.liked_post?(@post)
      @post.likes.find_by(user: current_user).destroy
      flash[:notice] = "You've unliked this post."
    else
      @like = @post.likes.build(user: current_user)

      # If the user has disliked the post, remove the dislike
      if current_user.disliked_post?(@post)
        @post.dislikes.find_by(user: current_user).destroy
      end

      if @like.save
        flash[:notice] = "You've liked this post."
      else
        flash[:error] = "There was an error liking this post."
      end
    end

    redirect_back(fallback_location: root_path)
  end

  # PUT /posts/:id/dislike
  def dislike
    @post = Post.find(params[:id])

    # If the user has already disliked the post, remove the dislike
    if current_user.disliked_post?(@post)
      @post.dislikes.find_by(user: current_user).destroy
      flash[:notice] = "You've undisliked this post."
    else
      @dislike = @post.dislikes.build(user: current_user)

      # If the user has liked the post, remove the like
      if current_user.liked_post?(@post)
        @post.likes.find_by(user: current_user).destroy
      end

      if @dislike.save
        flash[:notice] = "You've disliked this post."
      else
        flash[:error] = "There was an error disliking this post."
      end
    end
    redirect_back(fallback_location: root_path)

  end

  # GET /posts/new
  def new
    @post = Post.new
    @is_link = params[:type] == 'link'
    @magazines = Magazine.all
  end

  # POST /posts or /posts.json
  def create
    @post = Post.new(post_params)
    @post.user_id = current_user.id
    @is_link = params[:type] == 'link'

    if @post.save
      redirect_to root_path, notice: 'Post was successfully created.'
    else
      @magazines = Magazine.all
      render :new
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
        format.json { render :show, status: :ok, location: @post }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1 or /posts/1.json
  def destroy
    @post.destroy

    respond_to do |format|
      format.html { redirect_to posts_url, notice: "Post was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  def sort_comments
    prepare_comments
    render 'show'
  end

  private

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
