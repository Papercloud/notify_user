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