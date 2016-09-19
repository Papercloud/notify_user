Rails.application.routes.draw do
  namespace :notify_user do
    get 'notifications', to: 'notifications#index'

    post 'notifications/mark_read', to: 'reads#create'
    post 'notifications/mark_all', to: 'reads#create_all'

    get 'notifications/count', to: 'unread_notifications#index_count'

    get 'notifications/subscriptions', to: 'subscriptions#index'
    post 'notifications/subscribe', to: 'subscriptions#create'
    delete 'notifications/unsubscribe', to: 'subscriptions#destroy'
    put 'notifications/update_batch', to: 'subscriptions#update_batch'
  end
end