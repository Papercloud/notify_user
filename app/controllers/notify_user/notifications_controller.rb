class NotifyUser::NotificationsController < NotifyUser::BaseNotificationsController 
	def redirect_logic(notification)
		render :text => "set redirect logic in notify_user/notifications_controller.rb"
		#notification redirect logic goes here
		#property = Property.find(@notification.params[:property_id])
		#redirect_to property_url(@property)
	end
end