Rails.application.routes.draw do
  resources :comments
  resources :magazines
  resources :posts
  resources :users
  resources :tweets
  resources :search, only: [:index]

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
  get 'search', to: 'search#index'
  root 'posts#index'
end
