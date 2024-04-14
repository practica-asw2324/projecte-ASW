Rails.application.routes.draw do
  resources :comments
  resources :magazines
  resources :posts
  resources :users

  resources :magazines do
    member do
      post 'subscribe'
      post 'unsubscribe'
    end
  end

  resources :posts do
    put 'like', on: :member
    put 'dislike', on: :member
    put 'boost', on: :member
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root 'posts#index'
end
