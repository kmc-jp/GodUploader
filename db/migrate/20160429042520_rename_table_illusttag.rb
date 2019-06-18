class RenameTableIllusttag < ActiveRecord::Migration[4.2]
  def change
    rename_table :Illust_tag, :illust_tags
  end
end
