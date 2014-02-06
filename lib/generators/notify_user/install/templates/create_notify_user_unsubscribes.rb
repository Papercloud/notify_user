class CreateNotifyUserUnsubscribes < ActiveRecord::Migration
  def change
    create_table :notify_user_unsubscribes do |t|
      t.string :type
      t.integer :target_id
      t.string :target_type
      t.timestamps
    end
  end
end
