require 'sinatra'
require 'fileutils'
require 'active_record'
require "sinatra/reloader"
require 'json'
require './models/illust.rb'
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
    "test"
  end

  def user 
    Account.find_by_kmcid(kmcid)
  end

end


get '/js/upload.js' do
  content_type :js
  erb :"upload.js", :layout => nil
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

  erb :upload

end

post '/uploadillust' do
  
  illust = user.illusts.build( title:params[:title] , caption:params[:caption] )

  if params[:illust]
    
      if illust.save 

        illust.filename = illust.id.to_s + "." + params[:illust][:filename].split('.').last
        illust.save       
 
        save_path = "./public/illusts/" + illust.filename
  
        File.open( save_path , 'wb' ) do |f|
          f.write params[:illust][:tempfile].read
        end

     #   session[:responce] = {code: 200, messages: "成功しました"}
     # else 
     #   session[:responce] = {code: 400, messages: photo.errors.full_messages}
     # end
    end
  end  



  redirect "/illust/" + illust.id.to_s

end

get '/illust/:id' do

  @illust = Illust.find_by_id( params[:id].to_i )
  erb :illust

end

get '/users/:kmcid' do
  
    @user = user
    erb :user

end 

get '/mypage' do
  
    @user = user
    erb :user

end 

#インデックス
get '/' do

  @accounts = Account.all
  erb :index

end
