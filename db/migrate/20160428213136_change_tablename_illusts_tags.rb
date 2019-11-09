class ChangeTablenameIllustsTags < ActiveRecord::Migration[4.2]
  def change
    rename_table :illusts_tags, :illust_tags
  end
end
