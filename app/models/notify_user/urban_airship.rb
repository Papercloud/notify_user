module NotifyUser
  class UrbanAirship < Apns

    # def push
    #   space_allowance = PAYLOAD_LIMIT - used_space

    #   payload = {
    #     :alias  => notification.target_id,
    #     :aps    => {
    #       :alert => notification.mobile_message(space_allowance),
    #       :badge => notification.count_for_target
    #     },
    #     :n_data => {
    #       '#' => notification.id,
    #       :t  => notification.created_at.to_time.to_i,
    #       '?' => notification.type
    #     }
    #   }

    #   payload[:n_data]['!'] = notification.params[:action_id] if notification.params[:action_id]

    #   response = Urbanairship.push(payload)
    #   if response.success?
    #     Rails.logger.info "Push notification sent successfully."
    #     return true
    #   else
    #     Rails.logger.info "Push notification failed."
    #     return false
    #   end
    # end

  end
end