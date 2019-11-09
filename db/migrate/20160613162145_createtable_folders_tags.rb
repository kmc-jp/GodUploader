class CreatetableFoldersTags < ActiveRecord::Migration[4.2]
  def change

    create_table :folderstags do |t|
      t.belongs_to :folder
      t.belongs_to :tag
      t.timestamps
    end

  end
end
