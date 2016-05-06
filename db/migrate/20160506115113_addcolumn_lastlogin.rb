class AddcolumnLastlogin < ActiveRecord::Migration
  def change
    add_column :accounts, :lastlogin,:time
  end
end
