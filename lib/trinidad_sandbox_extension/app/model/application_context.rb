require 'delegate'
require 'cgi'

require File.expand_path('../../helpers/sandbox', __FILE__)

module Trinidad
  module Sandbox
    class ApplicationContext < DelegateClass(Trinidad::Tomcat::Context)
      extend Trinidad::Sandbox::Helpers::Context

      def self.all
        apps = host ? host.find_children : []
        apps.select {|app| app.name != sandbox_context.name }.
          map {|app| ApplicationContext.new(app) }
      end

      def self.find(name)
        name = '/' + name unless name[0..1] == '/'
        path = CGI.unescape(name)
        context = host.findChild(path)
        ApplicationContext.new(context) if context
      end

      def initialize(context)
        super(context)
      end

      def slug
        @slug ||= CGI.escape(name.sub('/', ''))
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
        @parameters ||= find_parameters
      end
    end
  end
end

