require 'sinatra/base'
require 'sinatra/authorization'
require 'haml'

class SandboxApp < Sinatra::Base
  set :public, File.expand_path('../public', __FILE__)
  set :views, File.expand_path('../views', __FILE__)

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

  get '/' do
    login_required
    host = $servlet_context.getAttribute('tomcat_host')
    @applications = host ? host.findChildren() : []

    unless @applications.empty?
      @applications = @applications.sort {|a1, a2| a1.name <=> a2.name}
    end

    haml :index
  end

end
