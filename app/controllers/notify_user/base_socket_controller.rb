class NotifyUser::BaseSocketController < WebsocketRails::BaseController
	def client_connected
		Logger.debug "\n\n\n\n\n\nCONNECTED"
		send_message :new_notification, {}, namespace: 'notify_user'
	end
end