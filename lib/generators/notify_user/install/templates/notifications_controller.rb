class NotifyUser::NotificationsController < NotifyUser::BaseNotificationsController 
	def redirect_to
		render :text => "set redirect logic in notify_user/notifications_controller.rb"
		#notification redirect logic goes here
	end
end