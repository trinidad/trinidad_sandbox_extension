require 'rubygems'
require 'sinatra'
require 'haml'
require File.expand_path('../helpers/auth', __FILE__)
require File.expand_path('../helpers/context', __FILE__)
require File.expand_path('../helpers/deploy', __FILE__)
require File.expand_path('../helpers/view', __FILE__)
require File.expand_path('../model/application_context', __FILE__)
require 'sinatra/respond_to'
require 'sinatra/flash'

include Trinidad::Sandbox

enable :sessions

set :views, File.expand_path('../views', __FILE__)

Sinatra::Application.register Sinatra::RespondTo

helpers do
  include Helpers::Auth
  include Helpers::Context
  include Helpers::Deploy
  include Helpers::View
end

before do
  login_required if basic_auth_required?(request)
end

get '/' do
  redirect sandbox_context.path + '/apps'
end

get '/apps' do
  @applications = ApplicationContext.all
  @page_id = 'applications'

  respond_to do |wants|
    wants.html  { haml :applications }
    wants.xml   { haml :applications }
  end
end

post '/apps/:name/stop' do
  context = ApplicationContext.find(params[:name])

  context_not_found(params[:name]) unless context

  if context.name == sandbox_context.name ||
      (!enable_default? && context.name == 'default')
    $servet_context.log "can't stop the application"
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

post '/apps/:name/restart' do
  context = ApplicationContext.find(params[:name])

  context_not_found(params[:name]) unless context

  if context.name == sandbox_context.name ||
      (!enable_default? && context.name == 'default')
    $servet_context.log "can't restart the application"
    redirect_to_home 500
  end

  context.reload

  redirect_to_home 204
end

get '/deploy' do
  @page_id = 'deploy'

  respond_to do |wants|
    wants.html { haml :deploy }
  end
end

post '/deploy' do
  token_required(params)

  if params['payload']
    deploy_from_web_hook(params)
  elsif params['repo']
    deploy_from_form(params)
  else
    redirect_to_home 204
  end
end
