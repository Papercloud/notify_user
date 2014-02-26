module NotifyUser
  module ApplicationHelper
  	def unsubscribe_link(notification, text)
  		user_hash =  notification.generate_unsubscribe_hash
  		html = link_to(text, notify_user_notifications_unauth_unsubscribe_url(:type => notification.type, :token => user_hash.token))
  		return html.to_s.html_safe
  	end

  	def is_unsubscribeable?(notification)
  		return NotifyUser.unsubscribable_notifications.include? notification.type
  	end
  end
end
