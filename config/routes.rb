Rails.application.routes.draw do
  namespace :notify_user do
    resources :notifications, only: [:index]
    get 'notifications/unsubscribe' => 'notifications#unsubscribe'
    get 'notifications/subscribe' => 'notifications#subscribe'
    get 'notifications/unauth_unsubscribe' => 'notifications#unauth_unsubscribe'
    get 'notifications/subscriptions' => 'notifications#subscriptions'
    put 'notifications/subscriptions' => 'notifications#subscriptions'
    put 'notifications/mass_subscriptions' => 'notifications#mass_subscriptions'
    put 'notification/unsubscribe_from_object' => 'notifications#unsubscribe_from_object'

    post 'notifications/mark_read', to: 'reads#create'
    post 'notifications/mark_all', to: 'reads#create_all'

    get 'notifications/count', to: 'unread_notifications#index_count'
  end
end