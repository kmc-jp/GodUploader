require 'rubygems'
require 'bundler'
Bundler.require
require './app.rb'

Encoding.default_external = 'UTF-8'

run Sinatra::Application
