require_relative 'apn_connection'
require 'houston'

module NotifyUser
  class Houston < Apns

    NO_ERROR = -42
    INVALID_TOKEN_ERROR = 8
    CONNECTION = APNConnection.new

    attr_accessor :push_options

    def initialize(notifications, options)
      super(notifications, options)

      @push_options = setup_options

      device_method = @options[:device_method] || :devices
      begin
        @devices = @notification.target.send(device_method).to_a
      rescue
        Rails.logger.info "Notification target, #{@notification.target.class}, does not respond to the method, #{device_method}."
      end
    end

    def push
      send_notifications
    end

    private

    def connection
      CONNECTION.connection
    end

    def reset_connection
      CONNECTION.reset
    end

    def setup_options
      space_allowance = PAYLOAD_LIMIT - used_space

      mobile_message = ''
      if @notification.parent_id
        parent = @notification.class.find(@notification.parent_id)
        mobile_message = parent.mobile_message(space_allowance)
      else
        mobile_message = @notification.mobile_message(space_allowance)
      end
      mobile_message.gsub!('\n', "\n")

      push_options = {
        alert: mobile_message,
        badge: @notification.count_for_target,
        category: @notification.params[:category] || @notification.type,
        custom_data: @notification.params,
        sound: @options[:sound] || 'default'
      }

      if @options[:silent]
        push_options.merge!({
          alert: '',
          sound: '',
          content_available: true
        })
      end

      push_options
    end

    def valid?(payload)
      payload.to_json.bytesize <= PAYLOAD_LIMIT
    end

    def send_notifications
      connection.open if connection.closed?

      Rails.logger.info "PAYLOAD"
      Rails.logger.info "----"
      Rails.logger.info "#{@push_options}"

      unless valid?(@push_options)
        Rails.logger.info "Error: Payload exceeds size limit."
      end

      ssl = connection.ssl
      error_index = NO_ERROR

      @devices.each_with_index do |device, index|
        notification = ::Houston::Notification.new(@push_options.dup.merge({ token: device.token, id: index }))
        connection.write(notification.message)
      end

      Rails.logger.info "READING ERRORS"
      Rails.logger.info "----"
      read_socket, write_socket = IO.select([ssl], [], [ssl], 1)
      Rails.logger.info "#{ssl}"

      if (read_socket && read_socket[0])
        error = connection.read(6)

        Rails.logger.info "#{error}"

        if error
          command, status, error_index = error.unpack("ccN")

          Rails.logger.info "Error: #{status} with id: #{error_index}."

          # Remove all the devices prior to the error (we assume they were successful), and close the current connection:
          if error_index != NO_ERROR
            device = @devices.at(error_index)

            # If we encounter the Invalid Token error from APNS, just remove the device:
            if status == INVALID_TOKEN_ERROR
              Rails.logger.info "Invalid token encountered, removing device. Token: #{device.token}."
              device.destroy
            end

            @devices.slice!(0..error_index)
            reset_connection
          end
        end
      end

      # Resend all notifications after the once that produced the error:
      send_notifications if error_index != NO_ERROR
    rescue OpenSSL::SSL::SSLError, Errno::EPIPE, Errno::ETIMEDOUT => e
      Rails.logger.error "[##{connection.object_id}] Exception occurred: #{e.inspect}."
      reset_connection
      Rails.logger.debug "[##{connection.object_id}] Socket reestablished."
      retry
    end
  end
end
