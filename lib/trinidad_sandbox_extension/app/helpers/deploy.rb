module Trinidad
  module Sandbox
    module Helpers
      module Deploy
        require 'grit'
        require 'json'
        require 'gitable/uri'
        require 'fileutils'

        def deploy_from_form(params)
          repo_url = params["repo"]
          if repo_url.empty?
            repo_not_found
          else
            branch = params["branch"]
            branch = 'master' if branch.empty?

            ssh = normalize_uri repo_url
            path = params["path"]
            path = path_from_repo(ssh) if path.empty? && !enable_default?

            unless valid_path? path
              invalid_app_path(path)
            else
              status = find_and_deploy(ssh, branch, path)
              redirect_to_home status
            end
          end
        end

        def deploy_from_web_hook(params)
          payload = JSON.parse(params['payload'])
          url = payload['repository']['url']
          branch = File.basename payload['ref']

          ssh = normalize_uri url
          path = path_from_repo(ssh)

          status = find_and_deploy(ssh, branch, path)
        end

        def find_and_deploy(repo, branch, path)
          dest = File.join(host.app_base, path)

          deployed_app = ApplicationContext.find_by_doc_base(dest)
          status = if deployed_app
            redeploy_application(deployed_app, repo, branch, dest)
            204
          else
            deploy_new_application(path, repo, branch, dest)
            201
          end
        end

        def deploy_new_application(path, repo, branch, dest)
          clone(repo, branch, dest)
          bundle(dest)
          ApplicationContext.create(path, dest)
        end

        def redeploy_application(context, repo, branch, dest)
          context.send(:setPaused, true)
          FileUtils.rm_rf File.expand_path(dest)

          clone(repo, branch, dest)

          context.reload
        end

        private
        def clone(repo, branch, dest)
          Grit.debug = true
          Grit::Git.with_timeout(1000) do
            Grit::Git.new(dest).clone({:branch => branch}, repo, dest)
          end
        end

        def bundle(dest)
          Dir.chdir(dest) do
            `jruby -S bundle install` if File.exist? 'Gemfile'
          end
        end

        def normalize_uri(url)
          Gitable::URI.heuristic_parse(url).to_s
        end

        def path_from_repo(repo)
          Gitable::URI.heuristic_parse(url).project_name
        end

        def valid_path?(path)
          path.split('/').length == 1
        end
      end
    end
  end
end
