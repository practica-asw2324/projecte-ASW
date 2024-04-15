Rails.application.routes.draw do
  resources :comments do
    put 'like', on: :member
    put 'dislike', on: :member
  end

  resources :magazines
  resources :users

  resources :magazines do
    member do
      post 'subscribe'
      post 'unsubscribe'
    end
  end

  resources :posts do
    post 'react', on: :member
    get 'sort_comments', on: :member
    put 'like', on: :member
    put 'dislike', on: :member
    put 'boost', on: :member

  end

  root 'posts#index'
end
