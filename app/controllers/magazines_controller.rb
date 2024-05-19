class MagazinesController < ApplicationController
  before_action :authenticate_user, only: [:new, :create, :subscribe, :unsubscribe]
  before_action :set_magazine, only: %i[ show edit update destroy subscribe unsubscribe]
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
    @magazines = @magazines.reverse.map do |magazine|
      magazine.attributes.merge(
        posts_count: magazine.posts.count,
        comments_count: magazine.posts.sum { |post| post.comments.count },
        subscribers_count: magazine.users.count,
        current_user_subscribed: current_user ? magazine.users.include?(current_user) : false,
        owner: magazine.user.name
      )
    end

    respond_to do |format|
      format.html
      format.json { render json: @magazines.as_json() }
    end
  end

  def subscribe
    @subscription = @magazine.subscriptions.find_or_initialize_by(user_id: current_user.id)
    already_subscribed = !@subscription.new_record?


    respond_to do |format|
      if @subscription.save
        format.html { redirect_to request.referrer || root_path, alert: "You are already subscribed to this magazine." }
        format.json do
          if already_subscribed
            render json: { error: "You are already subscribed to this magazine." }, status: :conflict
          else
            @owner = @magazine.user.name
            render json: @magazine.as_json(except: [:updated_at], methods: [:posts_count, :comments_count, :subscribers_count]).merge(current_user_subscribed: true).merge(owner: @owner)
          end
        end
      else
        format.html { redirect_back(fallback_location: root_path, notice: "Unable to subscribe to this magazine.") }
        format.json { render json: { error: "Unable to subscribe to this magazine." }, status: :unprocessable_entity }
      end
    end
  rescue => e
    respond_to do |format|
      format.html { redirect_to request.referrer || root_path, alert: "An error occurred: #{e.message}" }
      format.json { render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error }
    end
  end

  def unsubscribe
    @subscription = @magazine.subscriptions.find_by(user_id: current_user.id)

    respond_to do |format|
      if @subscription&.destroy
        @owner = @magazine.user.name
        format.html { redirect_to request.referrer || root_path, notice: "Successfully unsubscribed from the magazine." }
        format.json { render json: @magazine.as_json(except: [:updated_at], methods: [:posts_count, :comments_count, :subscribers_count]).merge(current_user_subscribed: false).merge(owner: @owner)}
      else
        format.html { redirect_to request.referrer || root_path, alert: "You are not subscribed to this magazine." }
        format.json { render json: { error: "You are not subscribed to this magazine." }, status: :unprocessable_entity }
      end
    end
  rescue => e
    respond_to do |format|
      format.html { redirect_to request.referrer || root_path, alert: "An error occurred: #{e.message}" }
      format.json { render json: { error: "An error occurred: #{e.message}" }, status: :internal_server_error }
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
    @current_user_subscribed = current_user ? @magazine.users.include?(current_user) : false
    @owner = @magazine.user.name
  
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
      format.json { render json: @magazine.as_json(except: [:updated_at], methods: [:posts_count, :comments_count, :subscribers_count]).merge(current_user_subscribed: @current_user_subscribed).merge(owner: @owner) }
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
        format.json { render json: @magazine.as_json(except: [:updated_at], methods: [:posts_count, :comments_count, :subscribers_count]), status: :created }
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
        format.json { render json: @magazine.as_json(except: [:updated_at], methods: [:posts_count, :comments_count, :subscribers_count]) }
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
        format.json { head :no_content }
      end
    else
      respond_to do |format|
        format.html { redirect_to magazines_url, alert: "There was an error destroying the magazine." }
        format.json { render json: { error: "There was an error destroying the magazine." }, status: :unprocessable_entity }
      end
    end
  end

  def posts
    @magazine = Magazine.find(params[:id])
    @posts = @magazine.posts

    respond_to do |format|
      format.html
      format.json { render json: @posts.as_json(except: [:magazine_id, :user_id, :updated_at], methods: [:comments_count, :likes_count, :dislikes_count, :boosts_count, :user_name, :magazine_name]) }
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