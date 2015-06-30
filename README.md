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
Dynamic email titles use %{tags} that correspond to your params hash (Will throw an exception if key is missing)
```
channel :action_mailer,
      subject: "%{name} sent you a message",
      aggregate: {
        subject: "%{name} sent you %{count} messages"
      }
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

## APNS providers
By default, we use [Houston](https://github.com/nomad/houston/) to deliver push notifications via APNS from the server.

The initialiser for `notify_user` contains the following configuration when delivering via Houston:
```
# Number of connections Houston will maintain to APNS:
config.connection_pool_size = 3

# Time in seconds Houston will wait for a free connection before failing:
config.connection_pool_timeout = 300
```

We maintain persistent connections to APNS via background workers, and these values will allow you to configure how many connections the workers maintain, as well as the amount of time to wait for an idle connection before timing out.

You also need to provide exported versions of your push notification certificate and key as .pem files, these instructions come from the [APN on Rails](https://github.com/PRX/apn_on_rails) project on how to do that:

Once you have the certificate from Apple for your application, export your key
and the apple certificate as p12 files. Here is a quick walkthrough on how to do this:

1. Click the disclosure arrow next to your certificate in Keychain Access and select the certificate and the key.
2. Right click and choose `Export 2 items…`.
3. Choose the p12 format from the drop down and name it `cert.p12`.

Now covert the p12 file to a pem file:

    $ openssl pkcs12 -in cert.p12 -out apple_push_notification.pem -nodes -clcerts

`notify_user` will look for your pem files within `"#{Rails.root}/config/keys/`, named `development_push.pem` and `production_push`, for the development and production APNS gateways respectively.

## The Device model

When delivering via Houston, we also need access to a model which has access to device tokens that is related to your notification target. i.e. Assuming your notification target is a User:

```
class User < ActiveRecord::Base
  has_many :devices
end

class Device < ActiveRecord::Base
  belongs_to :user

  validates :token, presence:true # A string representation of your device's token, the only thing need to delivery push notifications.
end
```

A gem that provides such a model is [dre](https://github.com/Papercloud/dre), a mountable Rails engine that lets you flag a model (e.g. `User`) as a device owner and provides a number of routes to allow device registration.

By default, we assume the relation is named `:devices`, but this can be passed through when enabling APNS for a notification if you want to use something else:

```
channel :apns,
  aggregate_per: false,
  device_method: :some_other_method
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

##Upgrade v0.1.4 to v0.2
Run aggregate_interval generator which generates the migrations to add a sent_time field to notifications
```
rails generate notify_user:aggr_interval
rake db:migrate
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

