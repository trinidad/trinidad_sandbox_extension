module Trinidad
  module Sandbox
    module Helpers
      module Deploy
        require 'grit'

        def deploy_new_application(path, repo, branch, dest)
          clone(repo, branch, dest)
          Trinidad::Sandbox::ApplicationContext.create(path, dest)
        end

        def redeploy_application(context, repo, branch, dest)
          context.send(:setPaused, true)
          Dir.delete dest

          clone(repo, branch, dest)

          context.reload
        end

        private
        def clone(repo, branch, dest)
          Grit::Git.with_timeout(1000) do
            Grit::Git.new(dest).clone({:branch => branch}, repo, dest)
          end
        end
      end
    end
  end
end
