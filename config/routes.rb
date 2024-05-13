Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }

  devise_scope :user do
    delete 'sign_out', to: 'users#logout'
    get 'login', to: 'users#new', as: 'new_user'
  end

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
    resources :comments, only: [:create, :index, :destroy, :update] do
      put 'like', on: :member
      put 'dislike', on: :member
    end
  end

  get 'new_link', to: 'posts#new', type: 'link', as: :new_link
  get 'new_thread', to: 'posts#new', type: 'thread', as: :new_thread

  root 'posts#index'
end