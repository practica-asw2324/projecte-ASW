Rails.application.routes.draw do
  resources :comments
  resources :magazines
  resources :users

  resources :posts do
    post 'react', on: :member
    get 'sort_comments', on: :member
  end

  root 'posts#index'
end
