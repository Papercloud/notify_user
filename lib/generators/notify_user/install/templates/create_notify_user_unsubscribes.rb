class CreateNotifyUserUnsubscribes < ActiveRecord::Migration
  def change
    create_table :notify_user_unsubscribes do |t|
      t.string :type
      t.integer :target_id
      t.string :target_type

      t.integer :group_id
      t.timestamps
    end

    add_index :notify_user_unsubscribes, :group_id
    add_index :notify_user_unsubscribes, :target_id
  end
end
