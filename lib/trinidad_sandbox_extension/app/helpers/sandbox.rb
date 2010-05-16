
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

        def context_not_found(name)
          flash[:warning] = "application not found: #{name}"
          $servlet_context.log "application not found: #{name}"
          respond_to do |wants|
            wants.html { redirect sandbox_context.path }
            wants.xml { status 404 }
          end
        end

        def host
          $servlet_context.getAttribute('tomcat_host')
        end
      end
    end
  end
end
