class ChangeTableNameIllustsTags < ActiveRecord::Migration
  def change
    rename_table :illust_tags, :Illust_tag
  end
end
