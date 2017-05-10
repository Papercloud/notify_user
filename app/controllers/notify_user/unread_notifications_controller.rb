module NotifyUser
  class UnreadNotificationsController < ApplicationController
    before_filter :authenticate!

    def index_count
      unreads = collection.limit(100)
      render json: { count: collection.count }
    end

    private

    def collection
      NotifyUser::BaseNotification.for_target(@user)
        .where('parent_id IS NULL')
        .where('read_at IS NULL')
    end

    def authenticate!
      method(NotifyUser.authentication_method).call
      @user = method(NotifyUser.current_user_method).call
    end
  end
end
