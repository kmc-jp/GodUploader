class CreateIllusts < ActiveRecord::Migration[4.2]
  def change
    create_table :illusts do |t|
      t.string :title
      t.string :caption
      t.string :filename
      t.timestamps
    end
 
    create_table :tags do |t|
      t.string :name
      t.timestamps
    end
 
    create_table :illusts_tags do |t|
      t.belongs_to :illust
      t.belongs_to :tag
      t.timestamps
    end
  end
end
