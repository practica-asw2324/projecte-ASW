Rails.application.routes.draw do
  resources :tweets do
    put "like", on: :member
  end 
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root 'tweets#index'
end
