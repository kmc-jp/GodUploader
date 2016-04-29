class ChangeTablenameIllustsTags < ActiveRecord::Migration
  def change
    rename_table :illusts_tags, :illust_tags
  end
end
