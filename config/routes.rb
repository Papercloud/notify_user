Rails.application.routes.draw do
  namespace :notify_user do
    resources :notifications, only: [:index]
    put 'notifications/mark_read' => 'notifications#mark_read'
  end
end