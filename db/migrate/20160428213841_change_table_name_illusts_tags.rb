class ChangeTableNameIllustsTags < ActiveRecord::Migration[4.2]
  def change
    rename_table :illust_tags, :Illust_tag
  end
end
