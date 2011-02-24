require 'rubygems'
require 'sinatra'
require 'haml'
require File.expand_path('../helpers/sandbox', __FILE__)
require File.expand_path('../helpers/deploy', __FILE__)
require File.expand_path('../model/application_context', __FILE__)
require 'sinatra/respond_to'
require 'sinatra/flash'

include Trinidad::Sandbox

enable :sessions

set :views, File.expand_path('../views', __FILE__)

Sinatra::Application.register Sinatra::RespondTo

helpers {
  include Helpers::Auth
  include Helpers::Context
  include Helpers::Deploy
}
before { login_required }

get '/' do
  redirect sandbox_context.path + '/apps'
end

get '/apps' do
  @applications = ApplicationContext.all

  respond_to do |wants|
    wants.html  { haml :index }
    wants.xml   { haml :index }
  end
end

get '/apps/:name' do
  @app = ApplicationContext.find(params[:name])
  context_not_found(params[:name]) unless @app

  respond_to do |wants|
    wants.html { haml :app }
    wants.xml { haml :app }
  end
end

post '/apps/:name/stop' do
  context = ApplicationContext.find(params[:name])

  context_not_found(params[:name]) unless context

  if context.name == sandbox_context.name
    $servet_context.log "can't stop the sandbox application"
    redirect_to_home 500
  end

  context.stop
  $servlet_context.log "#{context.name} stopped"

  redirect_to_home 204
end

post '/apps/:name/start' do
  context = ApplicationContext.find(params[:name])

  context_not_found(params[:name]) unless context

  context.start
  if context.available == true
    $servlet_context.log "#{context.name} started successfully"
  else
    $servlet_context.log "#{context.name} start failed"
  end

  redirect_to_home 204
end

post '/apps/:name/redeploy' do
  context = ApplicationContext.find(params[:name])

  context_not_found(params[:name]) unless context

  context.reload

  redirect_to_home 204
end

get '/deploy' do
  repo_url = params[:repo]
  repo_not_found unless repo_url

  branch = params[:branch] || 'master'
  path = params[:path] || repo_url.split('/').last.sub('.git', '')

  dest = File.expand_path(path, host.app_base)

  status = if (deployed_app = ApplicationContext.find_by_doc_base(dest))
    redeploy_application(deployed_app, repo_url, branch, dest)
    204
  else
    deploy_new_application(path, repo_url, branch, dest)
    201
  end

  redirect_to_home status
end
