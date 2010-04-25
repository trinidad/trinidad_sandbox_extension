require 'sinatra/authorization'

module Trinidad
  module Sandbox
    module Helpers
      include Sinatra::Authorization

      def authorize(user, pass)
        user == sandbox_username && pass == sandbox_password
      end

      def authorized?
        sandbox_username && sandbox_password ? request.env['REMOTE_USER'] && !request.env['REMOTE_USER'].empty? : true
      end

      def authorization_realm; "Trinidad's sandbox"; end

      def name_to_path(name)
        '/' + (name == 'default' ? '' : name)
      end

      def host
        @host ||= $servlet_context.getAttribute('tomcat_host')
      end

      def sandbox_context
        @sandbox_context ||= $servlet_context.getAttribute('sandbox_context')
      end

      private
      def sandbox_username
        $servlet_context.getAttribute('sandbox_username')
      end

      def sandbox_password
        $servlet_context.getAttribute('sandbox_password')
      end
    end
  end
end
