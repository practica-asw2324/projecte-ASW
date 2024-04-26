class ApplicationController < ActionController::Base
  before_action :initialize_search
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  def initialize_search
    session[:last_search] ||= ''
  end

  private
  def authenticate_user
    if current_user.nil?
      redirect_to new_user_path, alert: "Please log in first"
    end
  end

  def record_not_found
    render json: { error: 'Record not found' }, status: :not_found
  end

  def current_user
    if request.format.html?
      super
    elsif request.format.json?
      api_key = request.headers['API-KEY']
      if api_key
        @current_user ||= User.find_by(api_key: api_key)
        
      else
        render json: { error: "You must provide an API key" }, status: :unauthorized
      end
    end
  end
end