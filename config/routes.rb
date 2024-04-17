Rails.application.routes.draw do
  devise_for :admins, controllers: { omniauth_callbacks: 'admins/omniauth_callbacks' }
  devise_scope :admin do
    get 'sign_in', to: 'admins/sessions#new', as: :new_admin_session
    post 'sign_in', to: 'admins/sessions#create', as: :admin_session
    delete 'sign_out', to: 'admins/sessions#destroy', as: :destroy_admin_session
  end


  resources :comments do
    put 'like', on: :member
    put 'dislike', on: :member
  end

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
