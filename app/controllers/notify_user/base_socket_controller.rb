class NotifyUser::BaseSocketController < WebsocketRails::BaseController
	def client_connected
	end
	def connected
		logger.debug "\n\nsocket connected"
		send_message :new_notification, {}, namespace: :notify_user
	end
end