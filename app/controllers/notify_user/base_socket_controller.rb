# 
# This is the websocket controller for telling the client a new message is availiable.
class NotifyUser::BaseSocketController < WebsocketRails::BaseController

	def get_channel
		"ch_" + connection_store[:user_id].to_s
	end
	
	def client_connected
		logger.debug "current_user is"
		logger.debug current_user.id
    connection_store[:id] = client_id
    connection_store[:user_id] = current_user.id
    WebsocketRails[get_channel].make_private
	end
	
	def connected
		logger.debug "\n\nsocket connected"
		logger.debug "\n\nplease subscribe to: "
		logger.debug connection_store[:user_id]
		trigger_success(get_channel)
	end

	def test_new_notification
		logger.debug "\n\n triggering new for " + get_channel
		NotifyUser.send_notification('new_my_property').to(User.find(connection_store[:user_id])).with(listing_address: "123 Main St").notify!
	end

  def authorize_channels
    # The channel name is passed inside the message Hash
		logger.debug "\n\n attempting private subscription for "
		logger.debug get_channel
		logger.debug message[:channel]
    if (get_channel == message[:channel])
			logger.debug "private channel accepted"
      accept_channel get_channel
    else
      deny_channel({message: 'authorization failed!'})
    end
  end
end