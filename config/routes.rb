Rails.application.routes.draw do
  namespace :notify_user do
    resources :notifications, only: [:index]
    put 'notifications/mark_read' => 'notifications#mark_read'
    get 'notifications/notifications_count' => 'notifications#notifications_count'
    get 'notifications/:id/read' => 'notifications#read'
    get 'notifications/mark_all' => 'notifications#mark_all'
    get 'notifications/unsubscribe' => 'notifications#unsubscribe'
    get 'notifications/subscribe' => 'notifications#subscribe'
    get 'notifications/unauth_unsubscribe' => 'notifications#unauth_unsubscribe'
    get 'notifications/subscriptions' => 'notifications#subscriptions'
    put 'notifications/subscriptions' => 'notifications#subscriptions'
  end
end