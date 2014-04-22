class MoveParamsToJson < ActiveRecord::Migration
  def change
  	system('rake notify_user:move_params_to_json')

  	remove_column :notify_user_notifications, :params
  	rename_column :notify_user_notifications, :json, :params
  end
end
