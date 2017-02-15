require_relative './convox'
require 'byebug'

class NoGitRepoConfigured < StandardError; end

class Application
  attr_accessor :name, :environment, :env_file, :github, :post_deploy, :resources

  def initialize(json)
    @name = json['app']
    @environment = json['environment']
    @github = json['github']
    @post_deploy = json['post_deploy']
    @dependencies = json['depends_on']
    @env_file = json['env_file']

    resources = json['resources'] || []

    @resources = resources.map do |s_json|
      ::Resource.new(s_json, deploy_name)
    end
  end

  def create
    system "convox apps create #{deploy_name} --wait"
  end

  def update_source
    raise  NoGitRepoConfigured unless @github

    byebug

    system <<-EOC
      mkdir -p _build;
      cd _build;
      git clone #{@github} #{@name};
      cd #{@name} && git pull origin master;
    EOC
  end

  def deploy
    system "cd _build/#{@name} && convox deploy -a #{deploy_name} --wait"

    system "#{@post_deploy} #{deploy_name}" if @post_deploy
  end

  def deploy_name
    "#{@name}-#{@environment}"
  end

  def update_resource_env_vars
      env = resources.map {|resource| [resource.env_var_name, resource.url]}

      Convox.set_env(deploy_name, Hash[env]) unless env.empty?
  end

  def update_dependency_env_vars
    return unless @dependencies && !@dependencies.empty?

    env =
      @dependencies.map do |service, config|
        process_type = config['process_type']
        env_var_name = config['env_var_name']
        transform = config['transform']

        host = Convox.app_url("#{service}-#{environment}", process_type)

        if transform
          host = `#{transform} #{host}`.chomp
        end

        [env_var_name, host]
      end

    Convox.set_env(deploy_name, Hash[env])
  end

  def update_base_env_vars
    return unless @env_file

    system <<-EOC
      cd _build/#{@name} && blackbox_postdeploy;
      cat #{@env_file} | convox env set --app #{deploy_name} --promote;
    EOC

    Convox.watch do
      Convox.app_running_yet?(deploy_name)
    end
  end
end
