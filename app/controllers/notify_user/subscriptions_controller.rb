module NotifyUser
  class SubscriptionsController < ApplicationController
    before_filter :authenticate!

    def index
      subscriptions = NotifyUser::Unsubscribe.for_target(@user)
      render json: subscriptions
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
