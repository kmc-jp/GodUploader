class DropSessions < ActiveRecord::Migration[4.2]
  def change
    drop_table :sessions
  end
end
