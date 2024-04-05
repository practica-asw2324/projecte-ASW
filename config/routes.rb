Rails.application.routes.draw do
  resources :comments
  resources :magazines
  resources :posts
  resources :users

  resources :posts do
    post 'react', on: :member
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root 'posts#index'
end
