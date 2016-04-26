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

get '/:id' do
  

#  @session = getSessionByid(params[:id])
#  if @session == nil 
      
#    redirect "/error"

#  else 

    #アップロードされた画像を表示するための配列づくり
    @images = []
#    Dir.glob( @session.imagepath + "/*" ).each do |image|
#      @images.push( image.gsub( @session.imagepath , "" ) )
#    end

    erb :main

#  end  
   
end 

get '/mypage' do
  

#  @session = getSessionByid(params[:id])
#  if @session == nil 
      
#    redirect "/error"

#  else 

    #アップロードされた画像を表示するための配列づくり
    @images = []
#    Dir.glob( @session.imagepath + "/*" ).each do |image|
#      @images.push( image.gsub( @session.imagepath , "" ) )
#    end

    erb :main

#  end  
   
end 

#インデックス
get '/' do

  session[:id] = ""  

  erb :index
end
