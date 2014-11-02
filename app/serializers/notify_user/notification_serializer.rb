class NotifyUser::NotificationSerializer < ActiveModel::Serializer
  root :notifications

  attributes :id, :type, :message, :read, :params, :created_at

  def read
    object.read?
  end
end