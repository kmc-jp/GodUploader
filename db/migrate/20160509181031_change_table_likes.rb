class ChangeTableLikes < ActiveRecord::Migration
  def change

    change_table :likes do |t|
      t.belongs_to :account
      t.belongs_to :illust
    end

  end
end
