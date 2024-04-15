class SearchController < ApplicationController
  def index
    @search_term = params[:search]
    @results = Post.where("title LIKE ?", "%#{@search_term}%")
  end
end