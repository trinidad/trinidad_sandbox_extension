require 'rubygems'
require 'trinidad'

require File.expand_path('../../trinidad-libs/trinidad-sandbox-extension', __FILE__)

module Trinidad
  module Extensions
    class SandboxServerExtension < ServerExtension
      VERSION = '0.3.0'

      def configure(tomcat)
        opts = prepare_options

        app_context = create_application_context(tomcat, opts)

        web_app = Trinidad::RackupWebApp.new({}, opts,
          'org.jruby.trinidad.SandboxRackServlet', 'SandboxServlet')

        app_context.add_lifecycle_listener(Trinidad::Lifecycle::Default.new(web_app))
        web_app
      end

      def prepare_options
        opts = {
          :context_path => '/sandbox',
          :jruby_min_runtimes => 1,
          :jruby_max_runtimes => 2,
          :libs_dir => 'libs',
          :classes_dir => 'classes',
          :public => 'app/public'
        }

        opts.deep_merge!(@options)
        opts[:rackup] = 'config.ru'
        opts[:web_app_dir] = File.expand_path('../trinidad_sandbox_extension', __FILE__)
        opts
      end

      def create_application_context(tomcat, opts)
        app_ctx = tomcat.addWebapp(opts[:context_path], opts[:web_app_dir])
        app_ctx.privileged = true

        if opts[:username] && opts[:password]
          app_ctx.servlet_context.setAttribute("sandbox_username", opts[:username].to_s);
          app_ctx.servlet_context.setAttribute("sandbox_password", opts[:password].to_s);
        end

        app_ctx
      end
    end
  end
end
