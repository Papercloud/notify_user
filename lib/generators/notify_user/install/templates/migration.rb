class CreateNotifyUserNotifications < ActiveRecord::Migration
  def change
    create_table :notify_user_notifications do |t|
      t.string :type
      t.integer :target_id
      t.string :target_type
      t.text :params
      t.string :state

      t.timestamps
    end

    create_table :notify_user_unsubscribes do |t|
      t.string :type
      t.integer :target_id
      t.string :target_type
      t.timestamps
    end

    create_table :notify_user_user_hashes do |t|
      t.string :type
      t.integer :target_id
      t.string :target_type
      t.string :token
      t.boolean :active, default: true
      t.timestamps
    end
  end
end
