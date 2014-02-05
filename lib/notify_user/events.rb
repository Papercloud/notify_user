def setup_socket_event_routes
	puts "\nSetting up socket events map"

  # This is for the notify_user gem.
  WebsocketRails::EventMap.describe do

  namespace :websocket_rails do
    subscribe :subscribe_private, :to => NotifyUser::BaseSocketController, :with_method => :authorize_channels
  end
    subscribe :client_connected, to: NotifyUser::BaseSocketController, with_method: :client_connected
    namespace :notify_user do
      subscribe :connected, to: NotifyUser::BaseSocketController, with_method: :connected
      subscribe :test_new_notification, to: NotifyUser::BaseSocketController, with_method: :test_new_notification
    end
  end

end