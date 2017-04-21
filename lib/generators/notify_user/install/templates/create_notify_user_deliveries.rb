class CreateNotifyUserDeliveries < ActiveRecord::Migration
  def change
    create_table :notify_user_deliveries do |t|
      t.datetime :sent_at
      t.string :channel
      t.integer :deliver_in
      t.string :status
      t.string :reason

      t.integer :notification_id
      t.string :device_token

      t.timestamps
    end

    add_index :notify_user_deliveries, :notification_id
    add_index :notify_user_deliveries, :sent_at
  end
end
