require 'sinatra/base'
require 'haml'
require File.expand_path('../helpers/sandbox', __FILE__)
require File.expand_path('../model/application_context', __FILE__)

module Trinidad
  module Sandbox
    class App < Sinatra::Base
      set :public, File.expand_path('../public', __FILE__)
      set :views, File.expand_path('../views', __FILE__)

      helpers { include Trinidad::Sandbox::Helpers }
      before { login_required }

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

        Trinidad::Sandbox::ApplicationContext.dump(context)

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

        Trinidad::Sandbox::ApplicationContext.load(context)

        context.start
        if context.available == true
          puts "#{context.name} started successfully"
        else
          puts "#{context.name} start failed"
        end

        redirect sandbox_context.path
      end
    end
  end
end

