class RenameTableIllusttag < ActiveRecord::Migration
  def change
    rename_table :Illust_tag, :illust_tags
  end
end
