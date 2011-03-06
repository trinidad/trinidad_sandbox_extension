require 'delegate'
require 'cgi'
require 'trinidad'

require File.expand_path('../../helpers/sandbox', __FILE__)

module Trinidad
  module Sandbox
    class ApplicationContext < DelegateClass(Trinidad::Tomcat::Context)
      extend Trinidad::Sandbox::Helpers::Context

      def self.all
        apps = host ? host.find_children : []
        apps.select {|app| app.name != sandbox_context.name }.
          map {|app| ApplicationContext.new(app) }.
          sort {|app1, app2| app1.slug <=> app2.slug }
      end

      def self.find(name)
        escaped_name = ''
        unless name == 'default'
          escaped_name = '/' + name unless name[0..1] == '/'
        end
        path = CGI.unescape(escaped_name)
        context = host.findChild(path)
        ApplicationContext.new(context) if context
      end

      def self.find_by_doc_base(base)
        if (apps = host.find_children)
          apps.select {|app| app.doc_base == File.basename(base)}.first
        end
      end

      def self.create(url, path)
        web_app = Trinidad::WebApp.create({
          :jruby_min_runtimes => 1,
          :jruby_max_runtimes => 1
        }, {
          :context_path => (url == 'default' ? '' : "/#{url}"),
          :web_app_dir => File.basename(path)
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

        ApplicationContext.new(context)
      end

      def initialize(context)
        super(context)
      end

      def slug
        @slug ||= CGI.escape(name.sub('/', ''))
      end

      def name
        @name ||= super.empty? ? 'default' : super
      end

      def path
        @path ||= super.empty? ? '/' : super
      end

      def self_path
        @self_path ||= "#{ApplicationContext.sandbox_context.path}/apps/#{slug}"
      end

      def actions
        [
          {:rel => 'start', :href => "#{self_path}/start"},
          {:rel => 'stop', :href => "#{self_path}/stop"},
          {:rel => 'redeploy', :href => "#{self_path}/redeploy"}
        ]
      end

      def parameters
        @parameters ||= begin
          parameters = {}
          find_parameters.each do |param|
            value = find_parameter(param)
            parameters[param] = value if !value.nil? && !value.empty?
          end
          parameters
        end
      end
    end
  end
end

