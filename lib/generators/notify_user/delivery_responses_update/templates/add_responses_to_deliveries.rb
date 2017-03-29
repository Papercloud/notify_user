class AddResponsesToDeliveries < ActiveRecord::Migration
  def up
    add_column :notify_user_deliveries, :responses, :json
  end

  def down
    remove_column :notify_user_deliveries, :responses
  end
end
