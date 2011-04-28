module Trinidad
  module Sandbox
    module Helpers
      module Context
        def sandbox_context
          @sandbox_context ||= $servlet_context.getAttribute('sandbox_context')
        end

        def enable_default?
          !!$servlet_context.getAttribute('enable_default')
        end

        def readonly?
          !!$servlet_context.get_attribute('readonly')
        end

        def render_readonly
          warning "The console has been started as READONLY, you can access to that resource"
          redirect_to_home 401
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

        def available_context?(context)
          context.name != sandbox_context.name || enable_default? ||
            (!enable_default? && context.name == 'default')
        end
      end
    end
  end
end
