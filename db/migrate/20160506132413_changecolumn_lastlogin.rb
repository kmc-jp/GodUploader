class ChangecolumnLastlogin < ActiveRecord::Migration[4.2]
  def change
    change_column :accounts, :lastlogin,:datetime
  end
end
