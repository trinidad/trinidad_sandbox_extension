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

        def basic_auth_required?(request)
          !token_required?(request)
        end

        def token_required?(request)
          request.path == '/deploy'
        end

        def token_required(params, realm = authorization_realm)
          return if authorized_by_token?(params)
          response["WWW-Authenticate"] = %(Basic realm="#{realm}")
          throw :halt, [401, "Deploy Token Required"]
        end

        def authorized_by_token?(params)
          deploy_token.nil? || params[:deploy_token] == deploy_token
        end

        private
        def sandbox_username
          @sandbox_username ||= $servlet_context.getAttribute('sandbox_username')
        end

        def sandbox_password
          @sandbox_password ||= $servlet_context.getAttribute('sandbox_password')
        end

        def deploy_token
          @deploy_token ||= $servlet_context.get_attribute('deploy_token')
        end
      end
    end
  end
end
