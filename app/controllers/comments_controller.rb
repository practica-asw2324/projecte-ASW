class CommentsController < ApplicationController
  before_action :authenticate_user, only: %i[ create like dislike ]
  before_action :set_comment, only: %i[ show edit update destroy ]
  protect_from_forgery unless: -> { request.format.json? }
  before_action :check_user, only: [:edit, :update, :destroy]

  # GET /posts/:post_id/comments
  def index
    @post = Post.find(params[:post_id])
    @comments = @post.comments

    respond_to do |format|
      format.html
      format.json { render json: @comments.as_json(except: [:user_id, :updated_at, :post_id, :comment_id],
                                                   methods: [:replies_count, :likes_count, :dislikes_count, :user_name,
                                                             :post_title]) }
    end
  end

  # GET /comments/1 or /comments/1.json
  def show
    @post = Post.find(params[:id])
    @comments = @post.comments
  end

  # GET /comments/new
  def new
    @comment = Comment.new(user_id: 1)
  end

  # GET /comments/1/edit
  def edit
  end

  # POST posts/:post_id/comments or posts/:post_id/comments.json
  def create
    user = current_user
    @post = Post.find(params[:post_id])
    @comment = @post.comments.new(comment_params)
    @comment.user_id = user.id

    respond_to do |format|
      if @comment.save
        format.html { redirect_to post_url(@comment.post_id), notice: "Comment was successfully created." }
        format.json { render json: @comment.as_json(except: [:user_id, :updated_at, :post_id, :comment_id],
                                                     methods: [:replies_count, :likes_count, :dislikes_count, :user_name,
                                                               :post_title]) }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @comment.as_json(except: [:user_id, :updated_at, :post_id, :comment_id],
                                                     methods: [:replies_count, :likes_count, :dislikes_count, :user_name,
                                                               :post_title]) }
      end
    end
  end

  # PATCH/PUT posts/:post_id/comments/:id
  def update
    @post = Post.find(params[:post_id])
    @comment = @post.comments.find(params[:id])
    if @comment.update(comment_params)
      respond_to do |format|
        format.html { redirect_to post_path(@post), notice: 'Comment was successfully updated.' }
        format.json { render json: { message: "Post was successfully updated." }, status: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to post_url(@comment.post_id), alert: "There was an error updating the post." }
        format.json { render json: { message: "There was an error updating the post." }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE posts/:post_id/comments/:comment_id
  def destroy
    @comment = Comment.find(params[:id])
    @post = @comment.post
    Comment.where(comment_id: @comment.id).destroy_all
    if @comment.destroy
      respond_to do |format|
        format.html { redirect_to post_url(@comment.post_id), notice: "Comment was successfully destroyed." }
        format.json { render json: { message: "Post was successfully destroyed." }, status: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to post_url(@comment.post_id), alert: "There was an error destroying the post." }
        format.json { render json: { error: "There was an error destroying the post." }, status: :unprocessable_entity }
      end
    end
  end

  # PUT /posts/:post_id/comments/:id/like
  def like
    @comment = Comment.find(params[:id])
    @like = @comment.likes_comments.find_or_initialize_by(user: current_user)

    respond_to do |format|
      if @like.persisted?
        @like.destroy
        format.html { redirect_back(fallback_location: root_path, notice: "You've removed your like for this comment.") }
        format.json { render json: { likes_count: @comment.likes_comments.count, message: "You've removed your like for this comment." } }
      else
        # If the user has disliked the comment, remove the dislike
        if current_user.disliked_comment?(@comment)
          @comment.dislikes_comments.find_by(user: current_user).destroy
        end

        if @like.save
          format.html { redirect_back(fallback_location: root_path, notice: "You've liked this comment.") }
          format.json { render json: { likes_count: @comment.likes_comments.count, message: "You've liked this comment." } }
        else
          format.html { redirect_back(fallback_location: root_path, notice: "Unable to like this comment.") }
          format.json { render json: { error: "Unable to like this comment." }, status: :unprocessable_entity }
        end
      end
    end
  rescue => e
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path, notice: "An error occurred: #{e.message}") }
      format.json { render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error }
    end
  end

  # PUT posts/:post_id/comments/:comment_id/dislike
  def dislike
    @comment = Comment.find(params[:id])
    @dislike = @comment.dislikes_comments.find_or_initialize_by(user: current_user)

    respond_to do |format|
      if @dislike.persisted?
        @dislike.destroy
        format.html { redirect_back(fallback_location: root_path, notice: "You've removed your dislike for this comment.") }
        format.json { render json: { dislikes_count: @comment.dislikes_comments.count, message: "You've removed your dislike for this comment." } }
      else
        # If the user has liked the comment, remove the like
        if current_user.liked_comment?(@comment)
          @comment.likes_comments.find_by(user: current_user).destroy
        end

        if @dislike.save
          format.html { redirect_back(fallback_location: root_path, notice: "You've disliked this comment.") }
          format.json { render json: { dislikes_count: @comment.dislikes_comments.count, message: "You've disliked this comment." } }
        else
          format.html { redirect_back(fallback_location: root_path, alert: "There was an error disliking this comment.") }
          format.json { render json: { error: "There was an error disliking this comment." }, status: :unprocessable_entity }
        end
      end
    end
  rescue => e
    respond_to do |format|
      format.html { redirect_back(fallback_location: root_path, notice: "An error occurred: #{e.message}") }
      format.json { render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error }
    end
  end

  private
    def check_user
      @comment = Comment.find(params[:id])
      unless current_user == @comment.user
        respond_to do |format|
          format.html { redirect_to @comment, alert: "You are not authorized to perform this action." }
          format.json { render json: { error: "You are not authorized to perform this action." }, status: :forbidden }
        end
      end
    end

    def set_comment
      @comment = Comment.find(params[:id])
    end

  def comment_params
      params.require(:comment).permit(:body, :user_id, :comment_id)
  end

end
