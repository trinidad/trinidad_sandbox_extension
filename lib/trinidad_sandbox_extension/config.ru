require 'rubygems'
require 'sinatra'

gem 'trinidad_jars'
require 'trinidad/jars'

app_path = $servlet_context.get_real_path('app/sandbox.rb')
require app_path

set :environment, :development
set :app_file, app_path
disable :run

run Sinatra::Application
