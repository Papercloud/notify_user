Rails.application.routes.draw do
  namespace :notify_user do
    resources :notifications, only: [:index]
    put 'notifications/mark_read' => 'notifications#mark_read'
    get 'notifications/:id/read' => 'notifications#read'
  end
end