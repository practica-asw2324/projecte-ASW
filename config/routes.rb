Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
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
    member do
      post 'subscribe'
      post 'unsubscribe'
    end
  end

  resources :posts do
    post 'react', on: :member
    put 'like', on: :member
    put 'dislike', on: :member
    put 'boost', on: :member
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