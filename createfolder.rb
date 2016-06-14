require "rubygems"
require "active_record"

require './models/account.rb'
require './models/illust.rb'
require './models/illust_tag.rb'
require './models/folderstags.rb'
require './models/tag.rb'
require './models/comment.rb'
require './models/folder.rb'
require './models/like.rb'


ActiveRecord::Base.establish_connection(

  adapter: 'sqlite3',
  database: 'god.db'

)

Folder.delete_all

Illust.all.each do |i|
  
  if !Folder.joins(:illusts).exists?( :id => i.id ) 
    folder = i.account.folders.create( :title => i.title, :caption => i.caption )
    folder.illusts << i

    i.tags.all.each do |t|
      folder.tags << t
    end

    i.likes.all.each do |l|
      folder.likes << l
    end

    i.comments.all.each do |c|
      folder.comments << c
    end


    folder.save
  end
end

