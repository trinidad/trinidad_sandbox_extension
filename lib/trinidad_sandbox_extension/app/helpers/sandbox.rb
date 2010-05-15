
module Trinidad
  module Sandbox
    module Helpers

      module Auth
        require 'sinatra/authorization'
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
          @sandbox_username ||= $servlet_context.getAttribute('sandbox_username')
        end

        def sandbox_password
          @sandbox_password ||= $servlet_context.getAttribute('sandbox_password')
        end
      end

      module Context
        def sandbox_context
          @sandbox_context ||= $servlet_context.getAttribute('sandbox_context')
        end

        def host
          $servlet_context.getAttribute('tomcat_host')
        end
      end
    end
  end
end
