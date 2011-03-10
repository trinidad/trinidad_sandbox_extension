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

      module Context
        def sandbox_context
          @sandbox_context ||= $servlet_context.getAttribute('sandbox_context')
        end

        def enable_default?
          !!$servlet_context.getAttribute('enable_default')
        end

        def git_ssh?
          !!$servlet_context.getAttribute('git_ssh')
        end

        def context_not_found(name)
          warning "It seems the application #{name} is not running on Trinidad"
          redirect_to_home 404
        end

        def repo_not_found
          warning "The repository url is required to clone the application", :now
          respond_to_invalid_deploy
        end

        def invalid_app_path(path)
          warning "The path #{path} is not valid, please remove the slashes", :now
          respond_to_invalid_deploy
        end

        def host
          $servlet_context.getAttribute('tomcat_host')
        end

        def redirect_to_home(status_code)
          respond_to do |wants|
            wants.html { redirect sandbox_context.path }
            wants.xml { status status_code }
          end
        end

        def respond_to_invalid_deploy
          @page_id = 'deploy'
          respond_to do |wants|
            wants.html { haml :deploy }
            wants.xml { status 400 }
          end
        end

        def warning(message, req = :next)
          flash.send(req)[:warning] = message
          $servlet_context.log message
        end
      end
    end
  end
end
