class MagazinesController < ApplicationController
  before_action :authenticate_user, only: [:new, :create, :subscribe, :unsubscribe]
  before_action :set_magazine, only: %i[ show edit update destroy ]
  before_action :check_user, only: [:edit, :update, :destroy]
  protect_from_forgery unless: -> { request.format.json? }


  # GET /magazines or /magazines.json
  def index
    case params[:sort]
    when 'posts'
      @magazines = Magazine.all.sort_by { |magazine| magazine.posts.count }
    when 'comments'
      @magazines = Magazine.all.sort_by { |magazine| magazine.posts.sum { |post| post.comments.count } }
    when 'subscriptions'
      @magazines = Magazine.all.sort_by { |magazine| magazine.users.count }
    else
      @magazines = Magazine.all
    end
    @magazines = @magazines.to_a.reverse!
    @magazines = @magazines.map do |magazine|
      {
        magazine: magazine,
        posts_count: magazine.posts.count,
        comments_count: magazine.posts.sum { |post| post.comments.count },
        subscribers_count: magazine.users.count
      }
    end

    respond_to do |format|
      format.html
      format.json { render json: @magazines.as_json(except: [:user_id, :updated_at, :posts_count, :comments_count, :subscribers_count]) }
    end
  end

  def subscribe
    @magazine = Magazine.find(params[:id])
    if current_user.subscribed_magazines.include?(@magazine)
      respond_to do |format|
        format.html { redirect_to request.referrer || root_path, alert: "You are already subscribed to this magazine." }
        format.json { render json: { error: "You are already subscribed to this magazine." }, status: :unprocessable_entity }
      end
    else
      current_user.subscribed_magazines << @magazine
      respond_to do |format|
        format.html { redirect_to request.referrer || root_path, notice: "Successfully subscribed to the magazine." }
        format.json { render json: { message: "Successfully subscribed to the magazine." }, status: :ok }
      end
    end
  end

  def unsubscribe
    @magazine = Magazine.find(params[:id])
    subscription = Subscription.find_by(user_id: current_user.id, magazine_id: @magazine.id)
    if subscription
      subscription.delete
      respond_to do |format|
        format.html { redirect_to request.referrer || root_path, notice: "Successfully unsubscribed from the magazine." }
        format.json { render json: { message: "Successfully unsubscribed from the magazine." }, status: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to request.referrer || root_path, alert: "You are not subscribed to this magazine." }
        format.json { render json: { error: "You are not subscribed to this magazine." }, status: :unprocessable_entity }
      end
    end
  end


  # GET /magazines/1 or /magazines/1.json
  def show
    params[:sort] ||= 'newest'
    params[:type] ||= 'all'
    
    @posts = @magazine.posts.includes(:user, :comments)

    @posts_count = @posts.count
    @comments_count = @posts.sum { |post| post.comments.count }
    @subscribers_count = @magazine.users.count
  
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

    respond_to do |format|
      format.html
      format.json { render json: @magazine.as_json(except: [:user_id, :updated_at], methods: [:posts_count, :comments_count, :subscribers_count]) }
    end
  end

  # GET /magazines/new
  def new
    @magazine = Magazine.new
  end

  # GET /magazines/1/edit
  def edit
  end

  # POST /magazines or /magazines.json
  def create
    user = current_user

    @magazine = Magazine.new(magazine_params)
    @magazine.user_id = user.id

    respond_to do |format|
      if @magazine.save
        format.html { redirect_to magazine_url(@magazine), notice: "Magazine was successfully created." }
        format.json { render json: @magazine.as_json(except: [:user_id, :updated_at], methods: [:posts_count, :comments_count, :subscribers_count]), status: :created }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @magazine.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /magazines/1 or /magazines/1.json
  def update
    respond_to do |format|
      if @magazine.update(magazine_params)
        format.html { redirect_to magazine_url(@magazine), notice: "Magazine was successfully updated." }
        format.json { render json: @magazine.as_json(except: [:user_id, :updated_at], methods: [:posts_count, :comments_count, :subscribers_count]) }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { error: "There was an error updating the magazine.", errors: @magazine.errors }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /magazines/1 or /magazines/1.json
  def destroy
    @magazine.destroy

    if @magazine.destroy
      respond_to do |format|
        format.html { redirect_to magazines_url, notice: "Magazine was successfully destroyed." }
        format.json { render json: { message: "Magazine was successfully destroyed." }, status: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to magazines_url, alert: "There was an error destroying the magazine." }
        format.json { render json: { error: "There was an error destroying the magazine." }, status: :unprocessable_entity }
      end
    end
  end

  private
    def check_user
      @magazine = Magazine.find(params[:id])
      unless current_user == @magazine.user
        respond_to do |format|
          format.html { redirect_to @magazine, alert: "You are not authorized to perform this action." }
          format.json { render json: { error: "You are not authorized to perform this action." }, status: :forbidden }
        end
      end
    end


    # Use callbacks to share common setup or constraints between actions.
    def set_magazine
      @magazine = Magazine.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def magazine_params
      params.require(:magazine).permit(:name, :title, :description, :rules)
    end
end
