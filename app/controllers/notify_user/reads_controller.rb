module NotifyUser
  class ReadsController < ApplicationController
    before_filter :authenticate!

    def create
      @notification = NotifyUser::BaseNotification.for_target(@user).where(id: params[:notification_ids], read_at: nil)
      @notification.update_all(read_at: Time.zone.now)

      render json: @notifications, status: :created
    end

    def create_all
      @notifications = NotifyUser::BaseNotification.for_target(@user).where(read_at: nil)
      @notifications.update_all(read_at: Time.zone.now)

      render json: @notifications, status: :created
    end

    private

    def authenticate!
      method(NotifyUser.authentication_method).call
      @user = method(NotifyUser.current_user_method).call
    end
  end
end
