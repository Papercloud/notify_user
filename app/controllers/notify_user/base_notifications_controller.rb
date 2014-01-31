class NotifyUser::BaseNotificationsController < ApplicationController

  before_filter :authenticate!

  def index
    @notifications = NotifyUser::BaseNotification.for_target(@user)
                                                  .order("created_at DESC")
                                                  .limit(30)
                                                  .page(params[:page])

    respond_to do |format|
      format.html
      format.json {render :json => @notifications}
    end
  end

  def mark_read
    @notifications = NotifyUser::BaseNotification.for_target(@user).where('id IN (?)', params[:ids])
    @notifications.update_all(state: :read)
    render json: @notifications
  end

  #get 
  def read
    @notification = NotifyUser::BaseNotification.for_target(@user).where('id = ?', params[:id]).first
    @notification.mark_as_read
    redirect_to
  end

  def redirect_to
    render :text => "redirect setup goes here"
  end

  protected

  def default_serializer_options
    {
      each_serializer: NotifyUser::NotificationSerializer,
      template_renderer: self
    }
  end

  def authenticate!
    method(NotifyUser.authentication_method).call
    @user = method(NotifyUser.current_user_method).call
  end
end