class CreateNotifyUserNotifications < ActiveRecord::Migration
  def change
    create_table :notify_user_notifications do |t|
      t.string :type
      t.integer :target_id
      t.string :target_type
      t.text :params

      t.timestamps
    end
  end
end
