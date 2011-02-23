require 'rubygems'
require 'sinatra'
require 'haml'
require File.expand_path('../helpers/sandbox', __FILE__)
require File.expand_path('../model/application_context', __FILE__)
require 'sinatra/respond_to'
require 'sinatra/flash'
require 'grit'
require 'trinidad'

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

post '/apps/:name/redeploy' do
  context = Trinidad::Sandbox::ApplicationContext.find(params[:name])

  context_not_found(params[:name]) unless context

  context.reload

  respond_to do |wants|
    wants.html { redirect sandbox_context.path }
    wants.xml { status 204 }
  end
end

get '/deploy' do
  repo_url = params[:repo]
  branch = params[:branch] || 'master'
  path = params[:path] || repo_url.split('/').last.sub('.git', '')

  apps_path = host.app_base
  dest = File.expand_path(path, apps_path)

  Grit::Git.with_timeout(1000) do
    Grit::Git.new(dest).clone({:branch => branch}, repo_url, dest)
  end

  web_app = Trinidad::WebApp.create({
    :jruby_min_runtimes => 1,
    :jruby_max_runtimes => 1
  }, {
    :context_path => "/#{path}",
    :web_app_dir => path
  })

  context = Trinidad::Tomcat::StandardContext.new
  context.path = web_app.context_path
  context.doc_base = web_app.web_app_dir

  context.add_lifecycle_listener Trinidad::Tomcat::Tomcat::DefaultWebXmlListener.new

  config = Trinidad::Tomcat::ContextConfig.new
  config.default_web_xml = 'org/apache/catalin/startup/NO_DEFAULT_XML'
  context.add_lifecycle_listener config

  context.add_lifecycle_listener Trinidad::Lifecycle::Default.new(web_app)

  host.add_child context

  respond_to do |wants|
    wants.html { redirect sandbox_context.path }
    wants.xml { status 201 }
  end
end
