require 'sinatra/base'
require 'sinatra/authorization'
require 'haml'

class SandboxApp < Sinatra::Base
  set :public, File.expand_path('../public', __FILE__)
  set :views, File.expand_path('../views', __FILE__)

#           #
#  HELPERS  #
#           #

  helpers do
    include Sinatra::Authorization

    def authorize(user, pass)
      user == sandbox_username && pass == sandbox_password
    end

    def authorized?
      sandbox_username && sandbox_password ? request.env['REMOTE_USER'] && !request.env['REMOTE_USER'].empty? : true
    end

    def authorization_realm; "Trinidad's sandbox"; end

    private
    def sandbox_username
      $servlet_context.getAttribute('sandbox_username')
    end

    def sandbox_password
      $servlet_context.getAttribute('sandbox_password')
    end
  end

  before do
    login_required
  end

#          #
#  ROUTES  #
#          #

  get '/' do
    @applications = host ? host.findChildren() : []

    unless @applications.empty?
      @applications = @applications.map do |a|
        n = a.name.sub('/', '')
        n = 'default' if n == ''
        n
      end
    end

    haml :index
  end

  get '/:name/stop' do
    path = name_to_path(params[:name])
    context = host.findChild(path)

    unless context
      puts "context not found: #{path}"
      redirect sandbox_context.path
    end

    if context.name == sandbox_context.name
      puts "can't stop the sandbox context"
      redirect sandbox_context.path
    end

    app_parameters[context.name] = {}
    context.findParameters().each do |name|
      app_parameters[context.name][name] = context.findParameter(name)
    end

    context.stop
    puts "#{context.name} stopped"
    redirect sandbox_context.path
  end

  get '/:name/start' do
    path = name_to_path(params[:name])
    context = host.findChild(path)

    unless context
      puts "context not found: #{path}"
      redirect sandbox_context.path
    end

    if app_parameters[context.name]
      app_parameters[context.name].each do |k, v|
        context.addParameter(k, v)
      end
    end

    context.start
    if context.available == true
      puts "#{context.name} started successfully"
    else
      puts "#{context.name} start failed"
    end

    redirect sandbox_context.path
  end

  private
  def name_to_path(name)
    '/' + (name == 'default' ? '' : name)
  end

  def host
    @host ||= $servlet_context.getAttribute('tomcat_host')
  end

  def sandbox_context
    @sandbox_context ||= $servlet_context.getAttribute('sandbox_context')
  end

  def app_parameters
    @@app_parameters ||= {}
  end

end
