module NotifyUser
  class Apns

    #sends push notification
    def self.push_notification(notification)
      payload = {
        :aliases => ["#{notification.target_id}"],
        :aps => {alert: notification.mobile_message, badge: 1},
        :notification_data => {
          '#' => notification.id,     
          t: notification.created_at.to_time.to_i
        }
      }

      payload[:notification_data][:action_id] = notification.params[:action_id] if notification.params[:action_id]
      payload[:notification_data][:action_type] = notification.params[:action_type] if notification.params[:action_type]


      puts payload
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
