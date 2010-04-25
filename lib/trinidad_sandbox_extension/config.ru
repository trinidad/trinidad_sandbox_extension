require 'rubygems'

gem 'trinidad_jars'
require 'trinidad/jars'
require 'trinidad_sandbox_extension'
require 'trinidad_sandbox_extension/sandbox_app'

class Sinatra::Reloader < ::Rack::Reloader
  def safe_load(file, mtime, stderr)
    Sinatra::Application.reset!
    super
  end
end
#use Sinatra::Reloader

run Trinidad::Sandbox::App
