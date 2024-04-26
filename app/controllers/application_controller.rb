class ApplicationController < ActionController::Base
  before_action :initialize_search
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  rescue_from RuntimeError do |exception|
    render json: { error: exception.message }, status: :unauthorized
  end

  def initialize_search
    session[:last_search] ||= ''
  end

  private
  private

  private

  def authenticate_user
    if request.format.html?
      authenticate_user!
    elsif request.format.json?
      begin
        raise "Invalid API key" unless current_user
      rescue => e
        render json: { error: e.message }, status: :unauthorized
      end
    end
  end
  
  def current_user
    if request.format.html?
      super
    elsif request.format.json?
      api_key = request.headers['API-KEY']
      @current_user ||= User.find_by(api_key: api_key)
      raise "Invalid API key" unless @current_user
      @current_user
    end
  end

  def record_not_found
    render json: { error: 'Record not found' }, status: :not_found
  end
end