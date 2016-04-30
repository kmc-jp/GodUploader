require 'sinatra'
require 'fileutils'
require 'active_record'
require "sinatra/reloader"
require 'json'
require './models/illust.rb'
require './models/illust_tag.rb'
require './models/account.rb'
require './models/tag.rb'
require './models/comment.rb'
require 'erubis'

set :erb, :escape_html => true

$stdout.sync = true

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'god.db'
)

configure do
  use Rack::Session::Cookie,
  # :key => 'rack.session',
  # :domain => 'takumakei.blogspot.com',
  # :path => '/',
  :expire_after => 3600,
  :secret => 'changeme'
end 

set :public, File.dirname(__FILE__) + '/public'

#便利品
helpers do

  #指定したファイルを削除する

  def removeFile(path)
    if File.exist?(path)
      File.delete( path )
    end
  end

  def removeDir(path)
    # サブディレクトリを階層が深い順にソートした配列を作成
    dirlist = Dir::glob(path + "**/").sort {
      |a,b| b.split('/').size <=> a.split('/').size
    }
    # サブディレクトリ配下の全ファイルを削除後、サブディレクトリを削除
    dirlist.each {|d|
      Dir.foreach(d) {|f|
        File.delete(d+f) if ! (/\.+$/ =~ f)
      }
      Dir.rmdir(d)
    }
  end

  def getSessionByid(id)
    return Session.where( id: id ).first
  end

  def getSessionByname(name)
    return Session.where( name: name ).first
  end

  def main(se)
    return uri("/" + se.id.to_s)
  end

  def h(text)
    Rack::Utils.escape_html(text)
  end

  def kmcid 
    if request.env["REMOTE_USER"] == nil then
       "unknown_user"
    else 
      request.env["REMOTE_USER"]
    end
  end

  def user 
    Account.find_by_kmcid(kmcid)
  end

  def hidetags
    [ "R-18" , "R-18G" ]
  end

  def ishide(illust)

    flag = false

    hidetags.each do |t|
      if illust.tags.exists?( :name => t ) then
        flag = true
      end
    end

    flag

  end

  def create_account
    if !Account.exists?( :kmcid => kmcid ) then
      Account.create( kmcid:kmcid , name:kmcid )
    end
  end

end

get '/js/upload.js' do
  content_type :js
  erb :"upload.js", :layout => nil
end
get '/js/user.js' do
  content_type :js
  erb :"user.js", :layout => nil
end

post '/confirmpassword/:id' do
  se = getSessionByid(params[:id])
  session[:password] = params[:password]
  redirect main(se)
end

post '/tweetwithimage/:id' do

 se = getSessionByid(params[:id])

 redirect main(se)
end

get '/upload'do

  create_account

  erb :upload

end

get '/searchbytag/:tagid' do
  
  create_account

  @tag = Tag.find_by_id( params[:tagid] )
  @illusts = @tag.illusts

  erb :searchbytag

end

get '/tags' do
  @tags = Tag.all
  erb :tags
end

post '/uploadillust' do
  
  illust = user.illusts.build( title:params[:title] , caption:params[:caption] )

  if params[:illust]
    
      if illust.save 

         params[:tags].split(',').each do |t|
          if Tag.exists?( :name => t ) then
            illust.tags << Tag.find_by_name(t)
          else
            illust.tags.create( name:t )
          end
        end

        illust.filename = illust.id.to_s + "." + params[:illust][:filename].split('.').last
        illust.save       

        if File.exists?( uri( 'public/illusts', false ) )
          Dir.mkdir( uri( 'public/illusts' , false ) )
        end
 
        save_path = "./public/illusts/" + illust.filename
  
        File.open( save_path , 'wb' ) do |f|
          f.write params[:illust][:tempfile].read
        end

    end
  end  


  redirect uri( "/illust/" + illust.id.to_s , false )

end

post '/deleteillust/:id' do

  if Illust.exists?( :id => params[:id].to_i ) then
    Illust.find_by_id( params[:id].to_i ).destroy
  end
 
  redirect uri( "/illust/" + params[:id] , false )

end

post '/editillust/:id' do

  if Illust.exists?( :id => params[:id].to_i ) then
    illust = Illust.find_by_id( params[:id].to_i )
    
    illust.title = params[:title]
    illust.caption = params[:caption]
    illust.tags.delete_all

    params[:tags].split(',').each do |t|
      if Tag.exists?( :name => t ) then
        illust.tags << Tag.find_by_name(t)
      else
        illust.tags.create( name:t )
      end

    end

    illust.save

  end
 
  redirect uri( "/illust/" + params[:id] , false )

end

get '/illust/:id' do

  create_account

  if Illust.exists?( :id => params[:id].to_i )

    @illust = Illust.find_by_id( params[:id].to_i )

    erb :illust
  
  else
  
    erb :deletedillust
  
  end

end

get '/users/:kmcid' do
  
  create_account

  if kmcid == params[:kmcid] then
    redirect uri( '/mypage' , false )
  else 
    @user = Account.find_by_kmcid(params[:kmcid])
    erb :user
  end
end 

post '/illust/:id/comment' do
  
  illust = Illust.find_by_id(params[:id].to_i)

  comment = illust.comments.build( text:params[:comment] )
  comment.account = user
  comment.save

  redirect uri( '/illust/' + params[:id].to_s , false )

end

post '/changeusersettings' do

  a = user
  a.name = params[:name]
  a.save

  redirect uri( '/mypage' , false )

end

get '/mypage' do
  
  create_account

  @user = user
  erb :user

end 

#インデックス
get '/' do

  create_account

  @accounts = Account.all

  p Account.all

  erb :index

end
