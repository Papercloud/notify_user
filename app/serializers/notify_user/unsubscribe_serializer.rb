class NotifyUser::UnsubscribeSerializer < ActiveModel::Serializer
  type 'unsubscribe'
  attributes :id
end