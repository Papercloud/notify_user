class AddSentTimeToNotifications < ActiveRecord::Migration
  def change
    add_column :notify_user_notifications, :sent_time, :datetime
    add_column :notify_user_notifications, :group_id, :integer
    add_column :notify_user_notifications, :parent_id, :integer

    add_index :notify_user_notifications, :group_id
    add_index :notify_user_notifications, :parent_id
  end
end
