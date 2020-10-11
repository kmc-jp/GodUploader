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

  def thumbnail_image_height
    186
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

  @tag = Tag.includes(:folders).find_by_id( params[:tagid] )
  @folders = @tag.folders
                 .includes(:account, :illusts, :tags)
                 .order("created_at DESC")

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
  # アップロードしたいイラストが来てないのはリクエストがおかしいので400を返す
  return 400 unless params[:illusts]

  folder = user.folders.build( title:params[:title] , caption:params[:caption] )

  # フォルダ作れないのはなんかこっちがおかしい気がするので500
  return 500 unless folder.save

  # フォルダできたので投稿数を増やす
  user.folders_count += 1
  user.save

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

    # サムネイル生成とSlack共有
    # 時間かかるのでthreadに逃がす
    Thread.new do
      # サムネイル生成
      outdir = './public/thumbnail'
      basename = File.basename(save_path).split('.').first
      ext = File.extname(save_path)
      outfile = "#{outdir}/#{basename}#{ext}"
      # GIFアニメのサムネイル画像を作るためにがんばっている
      # めちゃくちゃなのでなんとかしたい！！
      if `identify #{save_path} | wc -l`.chomp.to_i > 1
        if `identify #{save_path} | cut -d' ' -f3 | sort | uniq | wc -l`.to_i > 1
          # フレームごとの差分を展開する
          system "convert #{save_path} -coalesce -resize x#{thumbnail_image_height} -layers optimize #{outfile}"
        else
          system "convert -resize x#{thumbnail_image_height} #{save_path} #{outfile}"
        end
      else
        system "convert -resize x#{thumbnail_image_height} #{save_path} #{outfile}"
      end

      # Slack共有
      if params[:isslack] && !params[:channel].nil? then
        if params[:isgyazo] then
          gyazo = Gyazo::Client.new access_token: ENV['gyazo_token']
          gyazo_path = "./public/thumbnail/" + folder.illusts.first.filename;  
          res = gyazo.upload(
            imagefile: gyazo_path,
            referer_url: "https://inside.kmc.gr.jp/godillustuploader/users/#{kmcid}",
            title: "GodIllustUploader #{user.name}"
          )
          folder.outurl = res[:url]
          folder.save
        end
        upload_post( params[:channel] , folder )
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
    # フォルダなくなったので投稿数を減らす
    user.folders_count -= 1
    user.save
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

  @active_accounts = Account.all
                            .select{ |a| a.folders_count > 0 }
                            .sort_by{ |a| a.folders_count * -1 }

  @newerillusts = Folder.distinct
                        .includes(:illusts, :account)
                        .left_joins(:tags)
                        .where('tags.name is null or tags.name not in (?)', hidetags)
                        .order("id DESC")
                        .limit(8)
  a = user
  @newcomments = Comment.distinct
                        .joins(:account)
                        .joins(:folder)
                        .joins('inner join accounts a2 on folders.account_id = a2.id')
                        .where("accounts.id <> ? and a2.id = ? and comments.created_at >= ?" , a.id, a.id, a.lastlogin)

  @newlikes = Folder.joins(:likes)
                    .where("folders.account_id = ? and likes.account_id <> ? and likes.created_at >= ?", a.id, a.id, a.lastlogin)
                    .map {|f| [f, f.likes]}

  a.lastlogin = Time.now
  a.save
  
  erb :index

end
