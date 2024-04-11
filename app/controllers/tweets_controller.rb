class TweetsController < ApplicationController
  before_action :set_tweet, only: %i[ show edit update destroy like]

  # GET /tweets or /tweets.json
  def index
    @tweets = Tweet.all.order(created_at: :desc)
  end

  # GET /tweets/1 or /tweets/1.json
  def show
  end

  # GET /tweets/new
  def new
    @tweet = Tweet.new
  end

  # GET /tweets/1/edit
  def edit
  end

  def like
    @tweet.like += 1
    @tweet.save
    respond_to do |format|
      format.html { redirect_to root_path }
      format.json { head :no_content }
      end
  end

  # POST /tweets or /tweets.json
  def create
    @tweet = Tweet.new(tweet_params)

    respond_to do |format|
      if @tweet.save
        if not session[:created_ids].nil?
          session[:created_ids].push(@tweet.id)

        else session[:created_ids] = [@tweet.id]

        end

        format.html { redirect_to root_path, notice: "Tweet was successfully created." }
        format.json { render :show, status: :created, location: @tweet }

      elsif @tweet.author.length < 4 and @tweet.content.length > 280
        format.html { redirect_to root_path, notice: "Author is too short (minimum is 4 characters) and Content is too long (maximum is 280 characters)" }
        format.json { render json: @tweet.errors, status: :unprocessable_entity }


      elsif @tweet.author.length < 4 and @tweet.content.length < 4
        format.html { redirect_to root_path, notice: "Author is too short (minimum is 4 characters) and Content is too short (minimum is 4 characters)" }
        format.json { render json: @tweet.errors, status: :unprocessable_entity }

      elsif @tweet.author.length < 4
        format.html { redirect_to root_path, notice: "Author is too short (minimum is 4 characters)" }
        format.json { render json: @tweet.errors, status: :unprocessable_entity }

      elsif @tweet.content.length < 4
        format.html { redirect_to root_path, notice: "Content is too short (minimum is 4 characters)" }
        format.json { render json: @tweet.errors, status: :unprocessable_entity }

      elsif @tweet.content.length > 280
        format.html { redirect_to root_path, notice: "Content is too long (maximum is 280 characters)" }
        format.json { render json: @tweet.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tweets/1 or /tweets/1.json
  def update
    respond_to do |format|
      if @tweet.update(tweet_params)
        format.html { redirect_to tweet_url(@tweet), notice: "Tweet was successfully updated." }
        format.json { render :show, status: :ok, location: @tweet }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tweet.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tweets/1 or /tweets/1.json
  def destroy
    if session[:created_ids].nil? or not session[:created_ids].include?(@tweet.id)
      respond_to do |format|
        format.html { redirect_to tweets_url, notice: "You are not allowed to delete this tweet." }
        format.json { head :forbidden }
        end

    else
      session[:created_ids].delete(@tweet.id)
      @tweet.destroy
      respond_to do |format|
        format.html { redirect_to tweets_url, notice: "Tweet was successfully destroyed." }
        format.json { head :no_content }
        end
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tweet
      @tweet = Tweet.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def tweet_params
      params.require(:tweet).permit(:author, :content)
    end
end
