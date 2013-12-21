Rails.application.routes.draw do
  namespace :notify_user do
    resources :notifications, only: [:index]
  end
end