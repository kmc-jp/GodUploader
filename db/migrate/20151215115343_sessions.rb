class Sessions < ActiveRecord::Migration[4.2]
  def change
    create_table :sessions do |t|
      t.string :name
      t.string :password
      t.string :endtime
      t.boolean :isstart, default: false,null: false
      t.boolean :isfinished, default: false,null: false
      t.integer :autoreload, default: 1,null: false
      t.string :odai
      t.string :selectedodai
      t.timestamps
    end  
  end
end
