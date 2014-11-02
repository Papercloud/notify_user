module NotifyUser
  class PubNub

    #sends push notification
    def self.push_notification(notification)
      pubnub = Pubnub.new(
        :origin => ENV['PN_ORIGIN'],
        :publish_key   => ENV['PN_PUBLISH_KEY'],
        :subscribe_key => ENV['PN_SUBSCRIBE_KEY'],
        :secret_key => ENV['PN_SECRET_KEY'],
        :logger => Logger.new(STDOUT)
      )

      pubnub.grant( auth_key: ENV['PN_SECRET_KEY'],
                    :read => true,
                    :write => true,
                    :ttl => 525600,
                    :http_sync => true
                  )

      pn_apns = {
        aps: {
          alert: notification.mobile_message,
          badge: 1,
          type: notification.type
        }
      }

      pn_apns[:aps][:action_id] = notification.params[:action_id] if notification.params[:action_id]
      
      pubnub.publish(
        channel: notification.target.uuid,
        http_sync: true,
        message: {
          pn_apns: pn_apns
        }
      )
    end
  end
end
