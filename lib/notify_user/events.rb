def setup_socket_event_routes
	puts "\nSetting up socket events map"

  # This is for the notify_user gem.
  WebsocketRails::EventMap.describe do
    subscribe :client_connected, to: NotifyUser::BaseSocketController, with_method: :client_connected
    namespace :notify_user do
      subscribe :connected, to: NotifyUser::BaseSocketController, with_method: :connected
    end
  end

end