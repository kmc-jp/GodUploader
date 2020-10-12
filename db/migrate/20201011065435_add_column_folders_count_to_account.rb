class AddColumnFoldersCountToAccount < ActiveRecord::Migration[5.2]
  def change
    change_table :accounts do |t|
      t.integer :folders_count, default: 0, null: false
    end
  end
end
