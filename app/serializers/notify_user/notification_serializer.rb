class NotifyUser::NotificationSerializer < ActiveModel::Serializer
  require 'cgi'
  root :notifications

  attributes :id, :type, :message, :read, :params, :created_at

  def message
    object.message
  end

  def read
    object.read?
  end
end