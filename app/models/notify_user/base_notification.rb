require 'sidekiq'

module NotifyUser
  class BaseNotification < ActiveRecord::Base
    # Override point in case of collisions, plus keeps the table name tidy.
    self.table_name = "notify_user_notifications"

    # The object (usually a user) to send the notification to
    belongs_to :target, polymorphic: true

    has_many :deliveries, foreign_key: 'notification_id'

    validates :target, presence: true
    validates :type, presence: true

    validate :presence_of_group_id
    validate :target_has_unsubscribed

    ## Notification description
    class_attribute :description
    self.description = ""

    ## Channels
    class_attribute :channels
    self.channels = {}

    ## Restricting the params to be sent
    class_attribute :sendable_attributes
    self.sendable_attributes = []

    ## True will implement a grouping/aggregation algorithm so that even though 10 notifications are delivered eg. Push Notifications
    ## Only 1 notification will be displayed to the user within the notification.json payload
    class_attribute :aggregate_grouping
    self.aggregate_grouping = false

    # Not sure about this. The JSON and web feeds don't fit into channels, because nothing is broadcast through
    # them. Not sure if they really need another concept though, they could just be formats on the controller.
    class_attribute :views
    self.views = {
      mobile_sdk: {
        template_path: Proc.new {|n| "notify_user/#{n.class.name.underscore}/mobile_sdk/notification" },
        aggregate_path: Proc.new {|n| "notify_user/#{n.class.name.underscore}/mobile_sdk/aggregate_notifications" }
      }
    }

    def params
      return {} if super.nil?
      super.with_indifferent_access
    end

    def sendable_params
      return params unless self.class.sendable_attributes.any?
      params.slice(*self.class.sendable_attributes.map(&:to_s))
    end

    ## Public Interface
    def to(user)
      self.target = user
      self
    end

    def with(*args)
      self.params = args.reduce({}, :update)
      self
    end

    def grouped_by_id(group_id)
      self.group_id = group_id
      self
    end

    # Send any emails / SMS / push notifications:
    def notify(deliver=true)
      if self.aggregate_grouping
        group_parents = parents_in_group.where('created_at >= ?', 24.hours.ago).order('created_at DESC')
        if group_parents.any?
          self.parent_id = group_parents.first.id
        end
      end

      save.tap do |success|
        Scheduler.schedule(self) if deliver && success
      end
    end

    # Check if a hash already exists for that user otherwise create a new one:
    def generate_unsubscribe_hash
      NotifyUser::UserHash.where(target: target)
        .where(type: self.type)
        .where(active: true)
        .first_or_create
    end

    # Return whether or not the target has unsubscribed from this notification:
    def target_has_unsubscribed?(channel_name=nil)
      return Unsubscribe.has_unsubscribed_from?(target, type, group_id, channel_name)
    end

    def read?
      read_at.present?
    end

    def mark_as_read!
      self.read_at = Time.zone.now
      self.save
    end

    def parents_in_group
      return self.class.none unless self.aggregate_grouping
      self.class.for_target(target)
        .where(parent_id: nil)
        .where(group_id: group_id)
    end

    # Scopes:
    def self.for_target(target)
      where(target: target)
    end

    # Get the unread count for a given target:
    def self.unread_count_for_target(target)
      for_target(target)
        .where('parent_id IS NULL')
        .where('read_at IS NULL')
        .count
    end

    # Configure a channel
    def self.channel(name, options={})
      channels_clone = self.channels.clone
      channels_clone[name] = options
      self.channels = channels_clone
    end

    def self.allow_sendable_attributes(*args)
      self.sendable_attributes = *args
    end

    private

    def presence_of_group_id
      if self.aggregate_grouping && group_id.blank?
        errors.add(:group_id, "required when aggregate_grouping is set to true")
      end
    end

    def target_has_unsubscribed
      errors.add(:target, (" has unsubscribed from this type")) if target_has_unsubscribed?
    end

    def should_deliver?
      pending? and not target_has_unsubscribed?
    end
  end
end
