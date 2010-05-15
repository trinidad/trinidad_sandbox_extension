require 'rubygems'
require 'sinatra'

gem 'trinidad_jars'
require 'trinidad/jars'

app_path = $servlet_context.get_real_path('app/sandbox.rb')
require app_path

set :environment, :development
set :public, File.expand_path('../public', __FILE__)
set :app_file, app_path
disable :run

run Sinatra::Application

#gem 'trinidad_jars'
#require 'trinidad/jars'
#require 'trinidad_sandbox_extension'
#require 'trinidad_sandbox_extension/sandbox_app'

#class Sinatra::Reloader < ::Rack::Reloader
#  def safe_load(file, mtime, stderr)
#    Sinatra::Application.reset!
#    super
#  end
#end
#use Sinatra::Reloader

#run Trinidad::Sandbox::App
