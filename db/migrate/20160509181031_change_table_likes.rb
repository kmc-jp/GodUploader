class ChangeTableLikes < ActiveRecord::Migration[4.2]
  def change

    change_table :likes do |t|
      t.belongs_to :account
      t.belongs_to :illust
    end

  end
end
