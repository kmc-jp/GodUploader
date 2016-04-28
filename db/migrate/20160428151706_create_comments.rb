class CreateComments < ActiveRecord::Migration
  def change

    create_table :commnets do |t|
      t.string :text
      t.timestamps
      t.belongs_to :account
      t.belongs_to :illust
    end

    change_table :illusts do |t|
      t.belongs_to :account
    end

  end
end
