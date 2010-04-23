require 'rubygems'
require 'trinidad'
$:.unshift(File.expand_path('../trinidad_sandbox_extension', __FILE__))

require 'trinidad/core_ext'
require 'trinidad/extensions'
require 'trinidad/web_app'
require 'trinidad/rackup_web_app'

require File.expand_path('../../trinidad-libs/trinidad-sandbox-extension', __FILE__)

module Trinidad
  module Extensions
    class SandboxServerExtension < ServerExtension
      VERSION = '0.1.0'

      def configure(tomcat)
        opts = prepare_options

        app_ctx = tomcat.addWebapp(opts[:context_path], opts[:web_app_dir])
        app_ctx.privileged = true

        servlet = tomcat.addServlet(app_ctx, 'sandboxServlet', 'org.jruby.trinidad.SandboxRackServlet')
        servlet.setLoadOnStartup(1)

        app_ctx.addServletMapping('/*', 'sandboxServlet')

        web_app = Trinidad::RackupWebApp.new(app_ctx, {}, opts)

        web_app.add_context_loader
        web_app.add_init_params
        web_app.add_web_dir_resources

        web_app.add_rack_context_listener
      end

      def prepare_options
        opts = {
          :context_path => '/sandbox',
          :jruby_min_runtimes => 1,
          :jruby_max_runtimes => 2,
          :libs_dir => 'libs',
          :classes_dir => 'classes',
        }

        opts.deep_merge!(@options)
        opts[:rackup] = 'lib/trinidad_sandbox_extension/config.ru'
        opts[:web_app_dir] = File.expand_path('../..', __FILE__)
        opts
      end
    end
  end
end
