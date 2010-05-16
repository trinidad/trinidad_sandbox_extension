require 'rubygems'
require 'sinatra'
require 'haml'
require File.expand_path('../helpers/sandbox', __FILE__)
require File.expand_path('../model/application_context', __FILE__)
require 'sinatra/respond_to'
require 'sinatra/flash'

enable :sessions

set :views, File.expand_path('../views', __FILE__)

Sinatra::Application.register Sinatra::RespondTo

helpers { 
  include Trinidad::Sandbox::Helpers::Auth
  include Trinidad::Sandbox::Helpers::Context
}
before { login_required }

get '/' do
  redirect sandbox_context.path + '/apps'
end

get '/apps' do
  @applications = Trinidad::Sandbox::ApplicationContext.all

  respond_to do |wants|
    wants.html  { haml :index }
    wants.xml   { haml :index }
  end
end

get '/apps/:name' do
  @app = Trinidad::Sandbox::ApplicationContext.find(params[:name])
  context_not_found(params[:name]) unless @app

  respond_to do |wants|
    wants.html { haml :app }
    wants.xml { haml :app }
  end
end

post '/apps/:name/stop' do
  context = Trinidad::Sandbox::ApplicationContext.find(params[:name])

  context_not_found(params[:name]) unless context

  if context.name == sandbox_context.name
    $servet_context.log "can't stop the sandbox application"
    respond_to do |wants|
      wants.html { redirect sandbox_context.path }
      wants.xml { status 500 }
    end
  end

  context.stop
  $servlet_context.log "#{context.name} stopped"

  respond_to do |wants|
    wants.html { redirect sandbox_context.path }
    wants.xml { status 204 }
  end
end

post '/apps/:name/start' do
  context = Trinidad::Sandbox::ApplicationContext.find(params[:name])

  context_not_found(params[:name]) unless context

  context.start
  if context.available == true
    $servlet_context.log "#{context.name} started successfully"
  else
    $servlet_context.log "#{context.name} start failed"
  end

  respond_to do |wants|
    wants.html { redirect sandbox_context.path }
    wants.xml { status 204 }
  end
end
