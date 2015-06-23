class AddSentTimeToNotifications < ActiveRecord::Migration
  def change
    add_column :notify_user_notifications, :sent_time, :datetime
  end
end
