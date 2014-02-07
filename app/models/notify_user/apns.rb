module NotifyUser
  class Apns

    #sends push notification
    def self.push_notification(notification)
      payload = {
        :device_tokens => ['"#{self.target_id}"'],
        :aps => {alert: notification.mobile_message, badge: 1},
        :notification_data => {
          id: notification.id, 
          type: notification.type,
          t: notification.created_at.to_time.to_i
        }
      }

      response = Urbanairship.push(payload)
        if response.success?
          puts "Push notification sent successfully."
          return true
        else
          puts "Push notification failed."
          return false
        end    
    end
  end
end
