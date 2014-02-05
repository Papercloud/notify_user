notify_user
===========


Install:
```
gem 'notify_user'
rails g notify_user:install
```

Getting started:
```
rails g notify_user:notification NewMyProperty
```

Edit views/notify_user/new_my_property/action_mailer/notification.html.erb, e.g.
```
<h3>We added <%= @notification.params[:listing_address] %> to your My Properties.</h3>
```

Then send:
```
NotifyUser.send_notification('new_my_property').to(user).with(listing_address: "123 Main St").notify
```



To run the tests:
```
BUNDLE_GEMFILE=gemfiles/rails40.gemfile bundle install
rspec spec
```

To run the tests like Travis:
```
gem install wwtd
wwtd
```

##Web interface
Display a list of notifications for a logged in user
```
visit /notify_user/notifications
```

Clicking on a notification gets marked as read and taken to the redirect_logic action (notifications_controller.rb)
```
def redirect_logic(notification)
	property = Property.find(@notification.params[:property_id])
	redirect_to property_url(@property)
end
```

Unsubscribing from a notification type, first add it to the notify_user.rb initilizer 
```
# Override the default notification type
config.unsubscribable_notifications = ['NewPostNotification']
```

Add line to environment.rb file to configure host url for mail notifications
```
config.action_mailer.default_url_options = { :host => "http://example.com" }

```

Users can manage their subscription statuses through the web interface
```
visit notify_user/notifications/unsubscribe
```
