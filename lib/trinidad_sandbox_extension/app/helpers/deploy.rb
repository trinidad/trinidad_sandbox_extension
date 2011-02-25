module Trinidad
  module Sandbox
    module Helpers
      module Deploy
        require 'grit'
        require 'json'
        require 'uri'

        def deploy_from_form(params)
          repo_url = params["repo"]
          if repo_url.empty?
            repo_not_found
          else
            branch = params["branch"] || 'master'
            path = params["path"] || path_from_repo(repo_url)

            status = find_and_deploy(repo_url, branch, path)

            redirect_to_home status
          end
        end

        def deploy_from_web_hook(params)
          payload = JSON.parse(params['payload'])
          url = payload['repository']['url']
          branch = payload['ref'].split('/').last

          ssh = ssh_uri url
          path = path_from_repo(ssh)

          status = find_and_deploy(ssh, branch, path)
        end

        def find_and_deploy(repo, branch, path)
          dest = File.expand_path(path, host.app_base)

          status = if (deployed_app = ApplicationContext.find_by_doc_base(dest))
            redeploy_application(deployed_app, repo, branch, dest)
            204
          else
            deploy_new_application(path, repo, branch, dest)
            201
          end
        end

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

        def ssh_uri(url)
          uri = URI.parse(url)

          "git@#{uri.host}#{uri.path.sub('/', ':')}.git"
        end

        def path_from_repo(repo)
          repo.split('/').last.sub('.git', '')
        end
      end
    end
  end
end
