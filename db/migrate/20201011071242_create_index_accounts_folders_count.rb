class CreateIndexAccountsFoldersCount < ActiveRecord::Migration[5.2]
  def change
    change_table :accounts do |t|
      t.index :folders_count
    end
  end
end
