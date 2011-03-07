module Trinidad
  module Sandbox
    module Helpers
      module View
        def link_to_deploy
          %q{<a href="deploy">deploy</a>}
        end

        def render_parameters(parameters)
          render = ''

          parameters.keys.sort.each_with_index do |key, index|
            column = find_column(parameters, index)

            klass = "column#{column}"
            klass << " reset" if column == 2 && find_column(parameters, index - 1) == 1

            render << %Q{<li class="#{klass}">#{key} => #{parameters[key]}</li>}
          end

          render
        end

        def render_host_name
          $servlet_context.get_attribute('host_name') || 'HOST_NAME'
        end

        def render_deploy_token
          $servlet_context.get_attribute('deploy_token') || 'SECRET_DEPLOY_TOKEN'
        end

        private
        def find_column(parameters, index)
          (parameters.length / 2) > index ? 1 : 2
        end
      end
    end
  end
end
