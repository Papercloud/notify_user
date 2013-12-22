class NotifyUser::NotificationSerializer < ActiveModel::Serializer
  root :notifications

  attributes :id, :message

  def message
    options[:template_renderer].render_to_string(:template => object.class.views[:mobile_sdk][:template_path].call(object),
                                                 :locals => {params: object.params},
                                                 :layout => false)
  end
end


# How does the message for JSON work?
# It's just another channel?
# But then how does the message for web work? Another channel again?
# I think I'd rather have just one controller.
# Just need a view to override and render
# Or maybe send the templates down with the data separately, then join on the client.
# Still need to be able to use templats eventually for things like APNS though.

# So we can render a template...just need to decide where to put it.