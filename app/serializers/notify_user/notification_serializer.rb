class NotifyUser::NotificationSerializer < ActiveModel::Serializer
  require 'cgi'
  root :notifications

  attributes :id, :type, :message, :read, :params, :created_at

  def message
    string = options[:template_renderer].render_to_string(:template => object.class.views[:mobile_sdk][:template_path].call(object),
                                                 :locals => {params: object.params},
                                                 :layout => false, :formats => [:html])
    return ::CGI.unescapeHTML("#{string}")
  end

  def read
    object.read?
  end
end