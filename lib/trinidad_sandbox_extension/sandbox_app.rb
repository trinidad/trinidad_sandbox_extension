require 'sinatra/base'
require 'haml'

class SandboxApp < Sinatra::Base

  set :public, File.expand_path('../public', __FILE__)
  set :views, File.expand_path('../views', __FILE__)

  get '/' do
    host = $servlet_context.getAttribute('tomcat_host')
    @applications = host ? host.findChildren() : []

    unless @applications.empty?
      @applications = @applications.sort {|a1, a2| a1.name <=> a2.name}
    end

    haml :index
  end

end
