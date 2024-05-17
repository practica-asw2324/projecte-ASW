Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }

  devise_scope :user do
    delete 'sign_out', to: 'users#logout'
    get 'login', to: 'users#new', as: 'new_user'
  end

  resources :users do
    get 'comments', on: :member
    get 'posts', on: :member
    get 'boosts', on: :member
  end

  resources :magazines do
      post 'subscribe', on: :member
      delete 'unsubscribe', on: :member
      get 'posts', on: :member
  end
  
  resources :posts do
    post 'react', on: :member
    get 'sort_comments', on: :member
    member do
      post 'like'
      delete 'like', action: :unlike
      post 'dislike'
      delete 'dislike', action: :undislike
      post 'boost'
      delete 'boost', action: :unboost
    end
    resources :comments, only: [:create, :index, :destroy, :update] do
      member do
        post 'like'
        delete 'like', action: :unlike
        post 'dislike'
        delete 'dislike', action: :undislike
      end
    end
  end

  get 'new_link', to: 'posts#new', type: 'link', as: :new_link
  get 'new_thread', to: 'posts#new', type: 'thread', as: :new_thread

  root 'posts#index'
end