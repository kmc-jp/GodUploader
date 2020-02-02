class CreateUniqueIndexAccountKmcid < ActiveRecord::Migration[5.2]
  def change
    change_table :accounts do |t|
      t.index :kmcid, unique: true
    end
  end
end
