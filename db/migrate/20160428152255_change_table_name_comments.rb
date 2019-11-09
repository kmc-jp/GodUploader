class ChangeTableNameComments < ActiveRecord::Migration[4.2]
  def change
    rename_table :commnets, :comments
  end
end
