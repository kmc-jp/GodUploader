require 'sinatra'
require 'fileutils'
require 'active_record'
require "sinatra/reloader"
require 'json'
require 'net/http'
require 'gyazo'
require './models/illust.rb'
require './models/illust_tag.rb'
require './models/account.rb'
require './models/tag.rb'
require './models/folderstags.rb'
require './models/comment.rb'
require './models/like.rb'
require './models/folder.rb'
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

# set :public, File.dirname(__FILE__) + '/public'

config = YAML.load_file( "config/config.yml" );

ENV['gyazo_token'] = config[:gyazo_token]
ENV['slack_url'] = config[:slack_url]

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

  def remote_user
    request.env["REMOTE_USER"] || request.env['HTTP_X_FORWARDED_USER']
  end

  def kmcid 
    if remote_user == nil then
       "unknown_user"
       #"hoge"
       #"piyo"
    else 
      remote_user
    end
  end

  def user 
    Account.find_by_kmcid(kmcid)
  end

  def hidetags
    [ "R-18" , "R-18G" ]
  end

  def ishide(folder)
    names = folder.tags.pluck(:name)
    hidetags.any? { |t| names.include? t }
  end

  def create_account
    if !Account.exists?( :kmcid => kmcid ) then
      Account.create( kmcid:kmcid , name:kmcid )
    end
  end

  def maxtitlelength
    "50"
  end

  def maxcaptionlength
    "5000"
  end
  def maxtaglength
    "96"
  end

  def thumbheight
    "320px"
  end

  def upload_post( channel , folder )

    tags = []
    folder.tags.each do |t|
      tags.push( t.name )
    end

    data = {
            "username" => "GodIllustUploader",
            "icon_emoji" => ":godicon:",
            "channel" => "#" + channel,
            "text"=> folder.account.name + "が新たな絵をアップロードなさいました！",
            "attachments"=> [
              {
                "title" => folder.title,
                "text" => folder.caption + "\n" + "タグ:" + tags.join(',') + "\n" + "URI:https://inside.kmc.gr.jp/godillustuploader/illust/" + folder.id.to_s,
                "image_url" => folder.outurl
              }
            ]
          }
    request_url = ENV['slack_url']
    uri = URI.parse(request_url)
    http = Net::HTTP.post_form(uri, {"payload" => data.to_json}) 
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

get '/js/tegaki.js' do
  content_type :js
  erb :"tegaki.js", :layout => nil
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
  @folders = @tag.folders

  erb :searchbytag

end

get '/tags' do
  @tags = Tag.all.includes(:folders)
  erb :tags
end

get '/tegaki' do
  erb :tegaki
end

post '/like' do

  u = user
  folder = Folder.find_by_id( params[:id].to_s )

  if u != nil and folder != nil then
    
    if folder.likes.exists?( :account_id  => u.id ) then
      like = folder.likes.find_by_account_id( u.id )
      like.destroy
    else
      like = folder.likes.build()
      like.account = u
    end
  
    like.save
  
  end

  redirect uri( "/illust/" + params[:id] , false )

end

post '/uploadillust' do
  
  folder = user.folders.build( title:params[:title] , caption:params[:caption] )
  if params[:illusts]
    
      if folder.save 

        params[:tags].split(',').each do |t|
          if !folder.tags.exists?( :name => t ) then
            if Tag.exists?( :name => t ) then
              folder.tags << Tag.find_by_name(t)
            else
              folder.tags.create( name:t )
            end
          end
        end

        params[:illusts].each do |buf|
          illust = folder.illusts.create

          if params[:tegaki] then
            illust.filename = illust.id.to_s + ".png"
          else 
            illust.filename = illust.id.to_s + "." + buf[:filename].split('.').last
          end
          illust.save       

          if !File.exists?( 'public/illusts' )
            Dir.mkdir( 'public/illusts' )
          end

          save_path = "./public/illusts/" + illust.filename

          illustbin = buf[:tempfile].read
          File.open( save_path , 'wb' ) do |f|
            f.write illustbin
          end

        end

        if params[:isslack] then
          
          if params[:channel] != nil then
           
            if params[:isgyazo] then

              gyazo = Gyazo::Client.new ENV['gyazo_token']
              gyazo_path = "./public/illusts/" + folder.illusts.first.filename;  
              res = gyazo.upload gyazo_path , { :url => 'https://inside.kmc.gr.jp/godillustuploader/users/' + kmcid , :title => "GodIllustUploader " + user.name  }

              folder.outurl = res[ 'url' ]
              folder.save
        
            end
            
            upload_post( params[:channel] , folder )
          
          end
        
        end
    end
  end  
  
  if params[:tegaki] then
    content_type :json
    data = { redirect: uri( "/illust/" + folder.id.to_s , false ) }
    data.to_json
  else 
    redirect uri( "/illust/" + folder.id.to_s , false )
  end

end

post '/deleteillust/:id' do

  if Folder.exists?( :id => params[:id].to_i ) then
    Folder.find_by_id( params[:id].to_i ).destroy
  end
 
  redirect uri( "/users/" + kmcid , false )

end

post '/editillust/:id' do

  if Folder.exists?( :id => params[:id].to_i ) then
    folder = Folder.find_by_id( params[:id].to_i )
    
    folder.title = params[:title]
    folder.caption = params[:caption]
    folder.tags.delete_all

    params[:tags].split(',').each do |t|
      if !folder.tags.exists?( :name => t ) then
        if Tag.exists?( :name => t ) then
          folder.tags << Tag.find_by_name(t)
        else
          folder.tags.create( name:t )
        end
      end
    end

    folder.save

  end
 
  redirect uri( "/illust/" + params[:id] , false )

end

get '/illust/:id' do

  create_account

  if Folder.exists?( :id => params[:id].to_i )

    @folder = Folder.find_by_id( params[:id].to_i )

    erb :illust
  
  else
  
    erb :deletedillust
  
  end

end

get '/folder/:id' do

  create_account

  if Folder.exists?( :id => params[:id].to_i )

    @folder = Folder.find_by_id( params[:id].to_i )

    erb :folder
  
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
    @folder = @user.folders
    erb :user
  end
end 

post '/illust/:id/comment' do
  
  folder = Folder.find_by_id(params[:id].to_i)

  comment = folder.comments.build( text:params[:comment] )
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
  @folders = Folder.find_by_account_id( user.id )
  
  erb :user

end 

get '/history' do

  create_account
  erb :history
end

#インデックス
get '/' do

  create_account

  @accounts = Account.all
  
  @newerillusts = Folder.joins(:illusts).includes(:tags).order( "created_at DESC" ).select{ |f| !ishide(f) }.uniq.slice(0,8)
  a = user
  @newcomments = Comment.where( "created_at >= ?" , a.lastlogin ).select{ |item| item.account.kmcid != kmcid && item.folder.account.kmcid == kmcid }.uniq

  @newlikes = []
  a.folders.each do |f|
    p f.illusts
    likes =  f.likes.where( "created_at >= ?" , a.lastlogin ).select{ |item| item.account.kmcid != kmcid && item.folder.account.kmcid == kmcid }.uniq
    if likes.count > 0 then
      @newlikes.push( [f,likes] )
    end
  end

  a.lastlogin = Time.now
  a.save
  
  erb :index

end
