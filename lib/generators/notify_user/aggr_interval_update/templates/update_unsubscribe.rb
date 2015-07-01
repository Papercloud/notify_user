class UpdateUnsubscribe < ActiveRecord::Migration
  def change
    add_column :notify_user_unsubscribes, :group_id, :integer
    add_index :notify_user_unsubscribes, :group_id
  end
end
