class ApplicationController < ActionController::Base
  before_action :initialize_search

  def initialize_search
    session[:last_search] ||= ''
  end

  private
  def authenticate_user
    if current_user.nil?
      redirect_to new_user_path, alert: "Please log in first"
    end
  end
end