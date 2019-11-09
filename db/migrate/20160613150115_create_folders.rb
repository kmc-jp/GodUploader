class CreateFolders < ActiveRecord::Migration[4.2]
  def change

    create_table :folders do |t|
      t.string :title
      t.string :caption
      t.string :outurl
      t.belongs_to :account
      t.timestamps
    end

    change_table :illusts do |t|
      t.belongs_to :folder
    end

    change_table :likes do |t|
      t.belongs_to :folder
    end

    change_table :tags do |t|
      t.belongs_to :folder
    end

    change_table :comments do |t|
      t.belongs_to :folder
    end

  end
end
