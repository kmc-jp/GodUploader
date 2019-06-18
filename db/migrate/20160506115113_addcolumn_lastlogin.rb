class AddcolumnLastlogin < ActiveRecord::Migration[4.2]
  def change
    add_column :accounts, :lastlogin,:time
  end
end
