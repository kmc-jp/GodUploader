require 'sinatra'
require 'fileutils'
require 'active_record'
require "sinatra/reloader"
require 'json'
require './models/sessions.rb'
require 'erubis'

set :erb, :escape_html => true

configure do
  use Rack::Session::Cookie,
  # :key => 'rack.session',
  # :domain => 'takumakei.blogspot.com',
  # :path => '/',
  :expire_after => 3600,
  :secret => 'changeme'
end 

set :public, File.dirname(__FILE__) + '/public'

class Session < ActiveRecord::Base
  DIRECTORY = "./public/sessions"

  def path
    DIRECTORY + "/" + self.id.to_s
  end
  def imagepath
    self.path + "/images"
  end

end

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

end

get '/js/time.js' do
  content_type :js
  erb :"time.js", :layout => nil
end

get '/getsession' do
  se = getSessionByid( params[:id] )
  content_type :json
  if se == nil 
    { isstart:false , isfinished:false }.to_json
  else
    { isstart: se.isstart , isfinished: se.isfinished }.to_json
  end
end

post '/endsession' do
  se = getSessionByid( params[:id] )
  se.isfinished = true  
  se.save
end

get '/autoreload' do

  se = getSessionByid( params[:id] )

  result = false
  if se.autoreload != session[:autoreload] then
    result = true
  end

  session[:autoreload] = se.autoreload
  { autoreload:result  }.to_json

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

#強制終了
post '/forceEnd/:id' do
   
  se = getSessionByid(params[:id])
 
  se.isstart = false
  se.autoreload = se.autoreload + 1
  session[:autoreload] = se.autoreload
  se.save
  
  redirect main(se)

end

#終了
post '/end/:id' do
  se = getSessionByid( params[:id] )
  redirect main(se)
end

#開始時の処理
post '/start/:id' do
  
  se = getSessionByid( params[:id] )

  se.endtime = Time.now + (params[:hours].to_i*(60*60)) + (params[:minutes].to_i*60) + (params[:seconds].to_i)
#   se.endtime = Time.now + (60*60)
  se.autoreload = se.autoreload + 1
  session[:autoreload] = se.autoreload

  se.isstart = true
  
  se.save
 
  redirect main(se)

end

#お題のアップロード
post '/uploadOdai/:id' do
  
  se = getSessionByid( params[:id] )

  se.autoreload = se.autoreload + 1
  session[:autoreload] = se.autoreload

  se.odai = ""

  if params[:odaiFile]
    
    buf = []
    params[:odaiFile][:tempfile].each_line do |line|     
      buf.push(line.force_encoding("UTF-8"))
    end
    
    p buf    
    se.odai = buf.join( ',' )
  end

  se.selectedodai = se.odai.split(',').sample(3).join(',')

  se.save

  redirect main( se )
end

#お題の獲得
post '/getOdai/:id' do
  
  se = getSessionByid( params[:id] )

  se.selectedodai = se.odai.split(',').sample(3).join(',')

  se.autoreload = se.autoreload + 1
  session[:autoreload] = se.autoreload

  se.save

  redirect main(se)

end

#画像のアップロード
post '/uploadImage/:id' do
  
  se = getSessionByid(params[:id])

  if params[:image]
    
    save_path = se.imagepath + "/#{Time.now.strftime("%y%m%d%H%M%S")}_#{rand(99999)}_#{params[:image][:filename]}"
  
    if !File.exists?( save_path )
      File.open( save_path , 'wb' ) do |f|
        f.write(params[:image][:tempfile].read)
      end
    end
  end  

  redirect main(se)

end

post '/open' do

    se = Session.new;
    se.name = params[:name]
    se.password = params[:password]
    
    se.selectedodai = ""
    se.odai = ""
    se.autoreload = 0
    session[:autoreload] = se.autoreload

    se.save

    session[:password] = params[:password]

    if File.exists?( uri( 'public/sessions', false ) )
      Dir.mkdir( uri( 'public/sessions' , false ) )
    end
    Dir.mkdir( se.path )
    Dir.mkdir( se.imagepath )

    redirect main(se)
end

get '/:id' do
  

  @session = getSessionByid(params[:id])
  if @session == nil 
      
    redirect "/error"

  else 

    session[:autoreload] = @session.autoreload

    #お題を表示するための配列作り
    @odai = []

    if @session.selectedodai != nil    
      @session.selectedodai.split( ',' ).each do |line|
        @odai.push( line )
      end
    end 

    #アップロードされた画像を表示するための配列づくり
    @images = []
    Dir.glob( @session.imagepath + "/*" ).each do |image|
      @images.push( image.gsub( @session.imagepath , "" ) )
    end

    @ismanager = false
    if @session.password == session[:password]
      @ismanager = true
    end
    erb :main

  end  
   
end 

#インデックス
get '/' do

  session[:password] = ""  

  @waitsessions = [] #開始前のセッション
  @drawingsessions = [] #ワンドロ中のセッション
  @endsessions = [] #終了済みのセッション

  Session.all.each do |s|
    if s.isstart
      if s.isfinished
        @endsessions.push(s)
      else 
        @drawingsessions.push(s)
      end 
    else
      @waitsessions.push(s)
    end
  end

  @waitsessions = @waitsessions.sort {|a,b| b.created_at <=> a.created_at }
  @drawingsessions = @drawingsessions.sort {|a,b| b.created_at <=> a.created_at}
  @endsessions = @endsessions.sort {|a,b| b.created_at <=> a.created_at}
  
  erb :index
end
