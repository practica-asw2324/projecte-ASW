class SearchController < ApplicationController
  def index
    if params[:search].present?
      @results = Post.where("title LIKE ? OR body LIKE ?", "%#{params[:search]}%", "%#{params[:search]}%")
    else
      @results = nil
    end
  end
end