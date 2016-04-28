class ChangeTableNameComments < ActiveRecord::Migration
  def change
    rename_table :commnets, :comments
  end
end
