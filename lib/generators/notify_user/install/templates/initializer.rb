NotifyUser.setup do |config|

  # Override the email address from which notifications appear to be sent.
  config.mailer_sender = "please-change-me-at-config-initializers-notify-user@example.com"

  # NotifyUser will call this within NotificationsController to ensure the user is authenticated.
  config.authentication_method = :authenticate_user!

  # NotifyUser will call this within NotificationsController to return the current logged in user.
  config.current_user_method = :current_user

  # Override the default notification type
  config.unsubscribable_notifications = ['NewPostNotification']

  # Provider for APNS:
  config.apns_provider = :houston

  # Number of connections Houston will maintain to APNS:
  config.connection_pool_size = 3

  # Time in seconds Houston will wait for a free connection before failing:
  config.connection_pool_timeout = 300

end