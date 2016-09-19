module NotifyUser
  class NotificationsController < ApplicationController
    before_filter :authenticate!

    def index
      collection
      respond_to_method
    end

    private

    def collection
      @notifications = NotifyUser::BaseNotification.for_target(@user)
                                                    .order("created_at DESC")
                                                    .where('parent_id IS NULL')
      collection_pagination
    end

    def collection_pagination
      @notifications = @notifications.page(page_number).per(per_page)
    end

    def page_number
      params[:page] || 1
    end

    def per_page
      params[:per_page] || 25
    end

    def respond_to_method
      respond_to do |format|
        format.html
        format.json {
          render json: @notifications, each_serializer: NotifyUser::NotificationSerializer, adapter: :json, meta: {
            pagination: { per_page: @notifications.limit_value, total_pages: @notifications.total_pages, total_objects: @notifications.total_count }
          }
        }
      end
    end

    def redirect_logic(notification)
      render :text => "redirect setup goes here"
    end

    def default_serializer_options
      { each_serializer: NotifyUser::NotificationSerializer }
    end

    def authenticate!
      method(NotifyUser.authentication_method).call
      @user = method(NotifyUser.current_user_method).call
    end
  end
end