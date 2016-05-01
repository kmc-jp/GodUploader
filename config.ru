require 'rubygems'
require 'bundler'
Bundler.require
require './app.rb'

Encoding.default_external = 'UTF-8'
Time.zone = "Tokyo"
ActiveRecord::Base.default_timezone = :local

run Sinatra::Application
