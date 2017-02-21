current_dir = File.dirname(__FILE__)

require "#{current_dir}/app"
require "#{current_dir}/resource"
require 'json'

class DontDestroyProductionPlease < StandardError; end

class Config
  attr_accessor :app, :resources

  def initialize(config_json)
    rack = `convox rack | grep Name | awk '{ print $2 }'`

    prod_error_message = 'Please do not run this on the production rack'
    raise DontDestroyProductionPlease, prod_error_message if production?(rack)

    @apps = config_json.map do |json|
      Application.new(json)
    end
  end

  def self.load
    file_name = "kraken.json"
    json = File.read(file_name)
    config_json = ::JSON.parse(json)
    Config.new(config_json)
  end

  def create
    @apps.each do |app|
      next if Settings.ignore?(app.name)

      app.resources.each &:create
      app.create

      app.update_source;
      app.set_git_ref
      app.update_base_env_vars
      app.update_resource_env_vars
      app.update_dependency_env_vars

      app.deploy if Settings.deploy?(app.name)
    end
  end

  def production?(rack)
    rack =~ /prod/ || rack =~ /convox/
  end
end
