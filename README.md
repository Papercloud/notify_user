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
NotifyUser.send_notification('new_my_property').to(user).with("listing_address" => "123 Main St").notify
```

To enable APNS add this line to your app/notification/notification_type.rb
```
channel :apns,
	aggregate_per: false    
```

To run the tests:
```
BUNDLE_GEMFILE=gemfiles/rails40.gemfile bundle install
BUNDLE_GEMFILE=gemfiles/rails40.gemfile bundle exec rspec spec
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
	class = notification.params[:type].capitalize.constantize
	object = class.find(@notification.params[:id])
	redirect_to property_url(object)
end
```
Add line to environment.rb file to configure host url for mail notifications
```
config.action_mailer.default_url_options = { :host => "http://example.com" }
```

##Subscriptions
Unsubscribing from a notification type, first add it to the notify_user.rb initilizer 
```
# Override the default notification type
config.unsubscribable_notifications = ['NewPostNotification','NewSale']
```
Users can manage their subscription statuses through the web interface
```
visit notify_user/notifications/unsubscribe
```
Unsubscribe link helper - add this to your views/notify_user/layouts/action_mailer.html.erb
```
<% if is_unsubscribeable? @notification  %>
	<p style="text-align: center;">
		<%= unsubscribe_link(@notification, "Unsubscribe") %>
	</p>
<% end %>
```

##Upgrading to JSON params data type
Run json_update generator which generates the migrations to change the params datatype to json as well as convert the current data to json
```
rails generate notify_user:json_update 
rake db:migrate
```

##Changes
Notification description and aggregates has changed syntax slighly from
```
@@description = "please override this type description" 
@@aggregate_per = 10.minutes
```
to 
```
self.description = "please override this type description" 
self.aggregate_per = 10.minutes
```

