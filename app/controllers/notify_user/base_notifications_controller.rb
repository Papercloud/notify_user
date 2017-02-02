class NotifyUser::BaseNotificationsController < ApplicationController

  before_filter :authenticate!, :except => [:unauth_unsubscribe]

  def index
    collection
    respond_to_method
  end

  def collection
    @notifications = NotifyUser::BaseNotification.for_target(@user)
                                                  .order("created_at DESC")
                                                  .where('parent_id IS NULL')
    collection_pagination
  end

  def collection_pagination
    @notifications = @notifications.page(params[:page]).per(params[:per_page])
  end

  def respond_to_method
    respond_to do |format|
      format.html
      format.json {render json: @notifications, each_serializer: NotifyUser::NotificationSerializer, adapter: :json, meta: { pagination: { per_page: @notifications.limit_value, total_pages: @notifications.total_pages, total_objects: @notifications.total_count } }}
    end
  end

  def mark_read
    @notifications = NotifyUser::BaseNotification.for_target(@user).where('id IN (?)', params[:ids])
    @notifications.update_all(read_at: Time.zone.now)
    render json: @notifications, each_serializer: NotifyUser::NotificationSerializer, adapter: :json
  end

  def mark_all
    @notifications = NotifyUser::BaseNotification.for_target(@user).where('read_at IS NULL')
    @notifications.update_all(read_at: Time.zone.now)
    render json: @notifications, each_serializer: NotifyUser::NotificationSerializer, adapter: :json
  end

  def notifications_count
    @notifications = NotifyUser::BaseNotification.for_target(@user)
      .where('parent_id IS NULL')
      .where('state IN (?)', ["sent_as_aggregation_parent", "sent", "pending"])

    render json: { :count => @notifications.count }
  end

  def unsubscribe_from_object
    case params[:subscription][:unsubscribe]
    when true
      NotifyUser::Unsubscribe.unsubscribe(@user, params[:subscription][:type], params[:subscription][:group_id])
    when false
      NotifyUser::Unsubscribe.subscribe(@user, params[:subscription][:type], params[:subscription][:group_id])
    else
      raise "unsubscribe field required"
    end

    render json: {status: "OK"}, status: 201
  end

  # GET
  def read
    @notification = NotifyUser::BaseNotification.for_target(@user).where('id = ?', params[:id]).first
    unless @notification.read?
      @notification.mark_as_read!
    end

    redirect_logic(@notification)
  end

  def redirect_logic(notification)
    render :text => "redirect setup goes here"
  end

  def unsubscribe
    if params[:type]
      NotifyUser::Unsubscribe.unsubscribe(@user, params[:type])
      redirect_to notify_user_notifications_unsubscribe_path
    end
    @types = build_notification_types
    @unsubscribale_types = NotifyUser.unsubscribable_notifications
    @unsubscribale_channels = NotifyUser::BaseNotification.channels
  end

  #endpoint for accessing subscriptions and their statuses
  def subscriptions
    update_subscriptions(params[:types]) if params[:types]
    @types = build_notification_types
    render :json => @types
  end

  def mass_subscriptions
    types = build_notification_types()
    if params[:type]
      types[:subscriptions].each do |type|
        unsubscribe = NotifyUser::Unsubscribe.has_unsubscribed_from(@user, type[:type])
        if params[:type][type[:type]] == "1"
          NotifyUser::Unsubscribe.unsubscribe(@user,type[:type])
        else
          if unsubscribe.empty?
            #if unsubscribe doesn't exist create it
            unsubscribe = NotifyUser::Unsubscribe.create(target: @user, type: type[:type])
          end
        end
      end
      flash[:message] = "Successfully updated your notifcation settings"
    end
    redirect_to notify_user_notifications_unsubscribe_path
  end

  def update_subscriptions(types)
    types.each do |type|
      unsubscribe = NotifyUser::Unsubscribe.has_unsubscribed_from(@user, type[:type])
      if type[:status] == '0'
        NotifyUser::Unsubscribe.unsubscribe(@user, type[:type])
      else
        NotifyUser::Unsubscribe.subscribe(@user, type[:type])
      end
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
    NotifyUser::Unsubscribe.subscribe(@user, params[:type]) if params[:type]
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
          status: NotifyUser::Unsubscribe.has_unsubscribed_from?(@user, type)}
    end

    #iterates over type
    notification_types.each do |type|
        types[:subscriptions] << {type: type, description: type.constantize.description,
          status: NotifyUser::Unsubscribe.has_unsubscribed_from?(@user, type)}
    end
    return types
  end

end