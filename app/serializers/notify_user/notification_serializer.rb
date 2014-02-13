class NotifyUser::NotificationSerializer < ActiveModel::Serializer
  root :notifications

  attributes :id, :type, :message, :read, :params, :action_id, :action_type, :created_at

  def message
    options[:template_renderer].render_to_string(:template => object.class.views[:mobile_sdk][:template_path].call(object),
                                                 :locals => {params: object.params},
                                                 :layout => false, :formats => [:html])
  end

  def action_id
    object.params[:action_id]
  end

  def action_type
    object.params[:action_type]
  end

  def read
    object.read?
  end
end