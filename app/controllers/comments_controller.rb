class CommentsController < ApplicationController
  before_action :set_comment, only: %i[ show edit update destroy ]

  # GET /comments or /comments.json
  def index
    @comments = Comment.all

  end

  # GET /comments/1 or /comments/1.json
  def show
    @post = Post.find(params[:id])
    @comments = @post.comments
  end

  # GET /comments/new
  def new
    @comment = Comment.new(user_id: 1) # Assuming user with ID 1 is the hardcoded user
  end

  # GET /comments/1/edit
  def edit
  end

  # POST /comments or /comments.json
  def create
    @comment = Comment.new(comment_params)
    @comment.user_id = 1

    respond_to do |format|
      if @comment.save
        format.html { redirect_to post_url(@comment.post_id), notice: "Comment was successfully created." }
        format.json { render :show, status: :created, location: @comment }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /comments/1 or /comments/1.json
  def update
    @comment = Comment.find(params[:id])
    if @comment.update(comment_params)
      redirect_to post_url(@comment.post_id), notice: 'Comment was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /comments/1 or /comments/1.json
  def destroy
    @comment = Comment.find(params[:id])
    @post = @comment.post
    Comment.where(comment_id: @comment.id).destroy_all
    @comment.destroy
    respond_to do |format|
      format.html { redirect_to post_url(@comment.post_id), notice: "Comment was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  # PUT /comments/:id/likes
  def like
    @comment = Comment.find(params[:id])
    userproves = User.find(id = 1)

    # If the user has already liked the comment, remove the like
    if userproves.liked_comment?(@comment)
      @comment.likes_comments.find_by(user: userproves).destroy
      flash[:notice] = "You've unliked this comment."
    else
      @like = @comment.likes_comments.build(user: userproves)

      # If the user has disliked the comment, remove the dislike
      if userproves.disliked_comment?(@comment)
        @comment.dislikes_comments.find_by(user: userproves).destroy
      end

      if @like.save
        flash[:notice] = "You've liked this comment."
      else
        flash[:error] = "There was an error liking this comment."
      end
    end

    redirect_back(fallback_location: root_path)
  end

  # PUT /comments/:id/dislike
  def dislike
    @comment = Comment.find(params[:id])
    userproves = User.find(id = 1)

    # If the user has already disliked the comment, remove the dislike
    if userproves.disliked_comment?(@comment)
      @comment.dislikes_comments.find_by(user: userproves).destroy
      flash[:notice] = "You've undisliked this comment."
    else
      @dislike = @comment.dislikes_comments.build(user: userproves)

      # If the user has liked the comment, remove the like
      if userproves.liked_comment?(@comment)
        @comment.likes_comments.find_by(user: userproves).destroy
      end

      if @dislike.save
        flash[:notice] = "You've disliked this comment."
      else
        flash[:error] = "There was an error disliking this comment."
      end
    end
    redirect_back(fallback_location: root_path)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_comment
      @comment = Comment.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def comment_params
      params.require(:comment).permit(:body, :user_id, :post_id, :comment_id)
    end
end
