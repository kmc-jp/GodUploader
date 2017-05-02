class CreatetableFoldersTags < ActiveRecord::Migration
  def change

    create_table :folderstags do |t|
      t.belongs_to :folder
      t.belongs_to :tag
      t.timestamps
    end

  end
end
