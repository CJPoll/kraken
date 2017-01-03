require_relative './convox'

class NoGitRepoConfigured < StandardError; end

class Application
  attr_accessor :name, :environment, :github, :post_deploy, :resources

  def initialize(json)
    @name = json['app']
    @environment = json['environment']
    @github = json['github']
    @post_deploy = json['post_deploy']
    @dependencies = json['depends_on']

    resources = json['resources'] || []

    @resources = resources.map do |s_json|
      ::Resource.new(s_json, deploy_name)
    end
  end

  def create
    system "convox apps create #{deploy_name} --wait"
  end

  def deploy
    raise  NoGitRepoConfigured unless @github

    system <<-EOC
    git clone #{@github};
    cd #{@name} && convox deploy -a #{@name}-#{@environment};
    EOC

    system @post_deploy if @post_deploy
  end

  def deploy_name
    "#{name}-#{environment}"
  end

  def update_resource_env_vars
      env = resources.map {|resource| [resource.env_var_name, resource.url]}

      Convox.set_env(deploy_name, Hash[env]) unless env.empty?
  end

  def update_dependency_env_vars
    return unless @dependencies

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
end
