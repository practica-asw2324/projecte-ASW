class ApplicationController < ActionController::Base
  before_action :authenticate_admin!
  protect_from_forgery with: :exception
  def hello
    render html: "<h1>It works WASLAB04!</h1>".html_safe
  end
end
