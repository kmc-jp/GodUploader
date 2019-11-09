class CreatetableLikes < ActiveRecord::Migration[4.2]
  def change

    create_table :likes do |t|
      t.timestamps
    end

  end
end
