class NotifyUser::NotificationSerializer < ActiveModel::Serializer
  root :notifications

  attributes :id, :type, :message, :read, :params, :created_at

  def message
    ActionController::Base.new.render_to_string(
      template: object.class.views[:mobile_sdk][:template_path].call(object),
      locals: {params: object.params},
      layout: false,
      formats: [:html]
    )
  end

  def read
    object.read?
  end
end