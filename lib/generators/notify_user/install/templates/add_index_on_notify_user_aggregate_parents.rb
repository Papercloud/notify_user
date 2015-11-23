class AddIndexOnNotifyUserAggregateParents < ActiveRecord::Migration
  def up
    unless index_exists?(:notify_user_notifications, :index_notify_user_notifications_on_target_id_and_last_activity_at)
      execute 'END'
      execute 'CREATE INDEX CONCURRENTLY index_notify_user_notifications_on_target_id_and_last_activity_at ON notify_user_notifications (target_id, last_activity_at DESC) WHERE parent_id IS NULL;'
      execute 'BEGIN'
    end
  end

  def down
    if index_exists?(:users, :index_notify_user_notifications_on_target_id_and_last_activity_at)
      execute 'DROP INDEX index_notify_user_notifications_on_target_id_and_last_activity_at;'
    end
  end
end