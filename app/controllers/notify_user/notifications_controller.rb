class NotifyUser::NotificationsController < ApplicationController

  before_filter :authenticate!

  def index
    @notifications = NotifyUser::BaseNotification.for_target(@user)
                                                  .order("created_at DESC")
                                                  .limit(30)
                                                  .page(params[:page])

    render json: @notifications
  end

  protected

  def authenticate!
    method(NotifyUser.authentication_method).call
    @user = method(NotifyUser.current_user_method).call
  end
end