class NotifyUser::NotificationsController < NotifyUser::BaseNotificationsController 
	def redirect_logic(notification)
		render :text => "set redirect logic in notify_user/notifications_controller.rb"
		# notification redirect logic goes here
		# class_name = notification.params[:action_type].capitalize.constantize
		# object = class_name.find(@notification.params[:action_id])
		# redirect_to property_url(object)
	end
end