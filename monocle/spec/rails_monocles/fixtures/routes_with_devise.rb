Rails.application.routes.draw do
  devise_for :users
  resources :authors
  root "authors#index"
end
