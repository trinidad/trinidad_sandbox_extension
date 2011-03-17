require 'rubygems'
require 'trinidad'

require File.expand_path('../../trinidad-libs/trinidad-sandbox-extension', __FILE__)

module Trinidad
  module Extensions
    class SandboxServerExtension < ServerExtension
      VERSION = '1.0.0'

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
          :public => 'app/public',
          :environment => 'production'
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
          app_ctx.servlet_context.set_attribute("sandbox_username", opts[:username].to_s);
          app_ctx.servlet_context.set_attribute("sandbox_password", opts[:password].to_s);
        end

        app_ctx.servlet_context.set_attribute('deploy_token', opts[:deploy_token]) if opts[:deploy_token]
        app_ctx.servlet_context.set_attribute('host_name', opts[:host_name]) if opts[:host_name]

        app_ctx.servlet_context.set_attribute('enable_default', boolean_option(opts[:enable_default]))

        app_ctx.servlet_context.set_attribute('git_ssh', boolean_option(opts[:git_ssh]))

        app_ctx.servlet_context.set_attribute('readonly', boolean_option(opts[:readonly], false))

        app_ctx
      end

      private
      def boolean_option(option, default = true)
        option.nil? ? default : option
      end
    end

    class SandboxOptionsExtension < OptionsExtension
      def configure(parser, default_options)
        default_options[:extensions] ||= {}
        default_options[:extensions][:sandbox] = {}
      end
    end
  end
end
