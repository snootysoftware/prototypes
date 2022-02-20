Rails.application.routes.draw do
  resources :posts
  resources :authors
  root "posts#index"
end
