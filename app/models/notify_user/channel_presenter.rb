require 'cgi'

module NotifyUser
  class ChannelPresenter
    include ActionView::Helpers::TextHelper

    def self.present(notification, length = nil)
      new(notification, length).present
    end

    def initialize(notification, length)
      @notification = notification
      @length = length
    end

    def present
      string = render_view
      string = truncate(string, length: length) if length.present? && length > 0
      return ::CGI.unescapeHTML("#{string}")
    end

    private

    attr_reader :notification, :length

    def template_path
      notification.class.views[:mobile_sdk][:template_path].call(notification)
    end

    def template_locals
      { params: notification.params, notification: notification }
    end

    def render_view
      ActionView::Base.new(ActionController::Base.view_paths).render(
        template: template_path,
        formats: [:html],
        locals: template_locals
      )
    end
  end
end
