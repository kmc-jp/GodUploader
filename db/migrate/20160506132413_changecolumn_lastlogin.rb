class ChangecolumnLastlogin < ActiveRecord::Migration
  def change
    change_column :accounts, :lastlogin,:datetime
  end
end
