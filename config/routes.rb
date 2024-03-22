Rails.application.routes.draw do
  resources :comments
  resources :magazines
  resources :posts
  resources :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root 'posts#index'
end
