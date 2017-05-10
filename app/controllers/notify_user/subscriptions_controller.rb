module NotifyUser
  class SubscriptionsController < ApplicationController
    before_filter :authenticate!

    def index
      render json: paginated_collection, adapter: :json, meta: {
        pagination: { per_page: paginated_collection.limit_value, total_pages: paginated_collection.total_pages, total_objects: paginated_collection.total_count }
      }
    end

    def create
      NotifyUser::Unsubscribe.subscribe!(@user, params[:type])
      render nothing: true, status: :created
    end

    def update_batch
      subscriptions = update_subscriptions(params[:types])
      render json: subscriptions
    end

    def destroy
      unsubscribe = NotifyUser::Unsubscribe.unsubscribe!(@user, params[:type])
      render json: unsubscribe
    end

    private

    def collection
      @collection ||= NotifyUser::Unsubscribe.for_target(@user)
    end

    def paginated_collection
      @paginated_collection ||= collection.page(page_number).per(per_page)
    end

    def page_number
      params[:page] || 1
    end

    def per_page
      params[:per_page] || 25
    end

    def authenticate!
      method(NotifyUser.authentication_method).call
      @user = method(NotifyUser.current_user_method).call
    end

    def update_subscriptions(types)
      types.each do |type|
        if type[:status] == '0'
          NotifyUser::Unsubscribe.unsubscribe!(@user, type[:type])
        else
          NotifyUser::Unsubscribe.subscribe!(@user, type[:type])
        end
      end
    end
  end
end
