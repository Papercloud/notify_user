class NotifyUser::NotificationSerializer < ActiveModel::Serializer
  root :notifications

  attributes :id, :message, :read

  def message
    options[:template_renderer].render_to_string(:template => object.class.views[:mobile_sdk][:template_path].call(object),
                                                 :locals => {params: object.params},
                                                 :layout => false)
  end

  def read
    object.read?
  end
end