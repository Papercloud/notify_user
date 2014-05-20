module NotifyUser
  class Apns
    SYMBOL_NAMES_SIZE = 10 
    PAYLOAD_LIMIT = 255

    #sends push notification
    def self.push_notification(notification)
      #calculates the bytes already used 
      used_space = SYMBOL_NAMES_SIZE + notification.id.size + notification.created_at.to_time.to_i.size +
                    notification.type.size
                    
      used_space += notification.params[:action_id].size if notification.params[:action_id]               

      space_allowance = PAYLOAD_LIMIT - used_space   

      payload = {
        :alias => notification.target_id,
        :aps => {alert: notification.mobile_message(space_allowance), badge: notification.count_for_target},
        :n_data => {
          '#' => notification.id,     
          t: notification.created_at.to_time.to_i, 
          '?' => notification.type
        }
      }
      payload[:n_data]['!'] = notification.params[:action_id] if notification.params[:action_id]

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
