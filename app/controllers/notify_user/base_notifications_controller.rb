class NotifyUser::BaseNotificationsController < ApplicationController

  before_filter :authenticate!, :except => [:unauth_subscribe]

  def index
    @notifications = NotifyUser::BaseNotification.for_target(@user)
                                                  .order("created_at DESC")
                                                  .limit(30)
                                                  .page(params[:page]).per(params[:per_page])

    respond_to do |format|
      format.html
      format.json {render :json => @notifications, meta: { pagination: { per_page: @notifications.limit_value, total_pages: @notifications.total_pages, total_objects: @notifications.total_count } }}
    end
  end

  def mark_read
    @notifications = NotifyUser::BaseNotification.for_target(@user).where('id IN (?)', params[:ids])
    @notifications.update_all(state: :read)
    render json: @notifications
  end

  def mark_all
    @notifications = NotifyUser::BaseNotification.for_target(@user).where('state IN (?)', ["pending","sent"])
    @notifications.update_all(state: :read)
    redirect_to notify_user_notifications_path  
  end

  def notifications_count
    @notifications = NotifyUser::BaseNotification.for_target(@user).where('state IN (?)', ["sent"])
    render json: {:count => @notifications.count}
  end

  #get 
  def read
    @notification = NotifyUser::BaseNotification.for_target(@user).where('id = ?', params[:id]).first
    @notification.mark_as_read
    redirect_logic(@notification)
  end

  def redirect_logic(notification)
    render :text => "redirect setup goes here"
  end

  def unsubscribe
    if params[:type]
      unsubscribe_from(params[:type])
      redirect_to notify_user_notifications_unsubscribe_path  
    end
    @unsubscribale_types = NotifyUser.unsubscribable_notifications
    @unsubscribale_channels = NotifyUser::BaseNotification.channels
  end

  #endpoint for accessing subscriptions and their statuses
  def subscriptions
    update_subscriptions(params[:types]) if params[:types]
    @types = build_notification_types
    render :json => @types
  end

  def update_subscriptions(types)
    types.each do |type|
      NotifyUser::Unsubscribe.toggle_status(@user, type)
    end 
  end

  def unauth_unsubscribe
    if params[:token] && params[:type]
      if NotifyUser::UserHash.confirm_hash(params[:token], params[:type])
        user_hash = NotifyUser::UserHash.where(token: params[:token], type: params[:type]).first
        @user = user_hash.target
        unsubscribe = NotifyUser::Unsubscribe.create(target: @user, type: params[:type])
        user_hash.deactivate
        return render :text => "successfully unsubscribed from #{params[:type]} notifications"
      else
        return render :text => "invalid token"
      end
    end
    return render :text => "Something went wrong please try again later"
  end

  def subscribe
    subscribe_to(params[:type]) if params[:type]
    redirect_to notify_user_notifications_unsubscribe_path
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

  private
  def build_notification_types()
    #dirty way to build a json hash with pagination
    types = {:subscriptions => []}

    notification_types = NotifyUser.unsubscribable_notifications

    #iterates over channels
    NotifyUser::BaseNotification.channels.each do |type, options|
        channel = (type.to_s + "_channel").camelize.constantize
        types[:subscriptions] << {type: type, description: channel.default_options[:description],
          status: NotifyUser::Unsubscribe.has_unsubscribed_from(@user, type).empty?}
    end 

    #iterates over type
    notification_types.each do |type|
        types[:subscriptions] << {type: type, description: type.constantize.description,
          status: NotifyUser::Unsubscribe.has_unsubscribed_from(@user, type).empty?}
    end 
    return types
  end

  def unsubscribe_from(type)
      unsubscribe = NotifyUser::Unsubscribe.new(target: @user, type: type)
      if unsubscribe.save
        flash[:message] = "successfully unsubscribed from #{type} notifications"
      else
        flash[:message] = "Please try again"
      end
  end

  def subscribe_to(type)
    NotifyUser::Unsubscribe.where(target: @user, type: type).destroy_all
    flash[:message] = "successfully subscribed to #{type} notifications"
  end
end