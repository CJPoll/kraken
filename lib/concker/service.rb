class UnknownServiceType < StandardError; end

module Service
  def self.new(json, app_name=nil)
    services = {
      'postgres' => Postgres,
      'redis' => Redis
    }
    type = json['type']
    service = services[type]

    if service
      service.new(json, app_name)
    else
      raise UnknownServiceType
    end
  end
end

class Command
  def initialize(base)
    @base = base
    @options = []
  end

  def add(option)
    @options << option
  end

  def to_s
    "#{@base} #{@options.map(&:to_s).join(' ')}"
  end

  def run
    cmd = self.to_s
    system cmd
  end
end

class Option
  attr_accessor :name, :type, :value

  def initialize(type, name, value=nil)
    @type = type
    @name = name
    @value = value
  end

  def to_s
    opt = ''
    case @type
    when :flag
      opt += "--#{@name}" if @value
    when :option
      opt += "--#{@name} #{@value}" if @value
    end
  end

  def self.from(hash, value)
    type = hash.key?(:flag) ? :flag : :option
    name = hash[type]

    Option.new(type, name, value)
  end
end

module Service
  def self.included(base)
    base.extend ClassMethods
  end

  def initialize(json, app_name)
    self.class.properties.each do |inst_var, hash|
      instance_variable_set(:"@#{inst_var}", json[inst_var.to_s])
    end

    @app_name = json['name'] || "#{app_name}-#{service_name}"
  end

  def service_name
    self.class.service_name
  end

  def create
    to_command(:create).run
  end

  module ClassMethods
    attr_accessor :service_name, :properties

    def props(map)
      name = @name
      @properties = map

      define_method(:to_command) do |command|
        name = self.class.service_name
        cmd = Command.new "convox services #{command} #{name}"

        map.each do |inst_var, hash|
          value = instance_variable_get(:"@#{inst_var}")
          option = Option.from(hash, value)
          cmd.add(option)
        end

        name_opt = Option.new(:option, 'name', @app_name)
        cmd.option(name_opt) if @app_name

        cmd
      end
    end
    
    def name(name)
      @service_name = name
    end
  end

  private
  def properties
    self.class.properties
  end
end

class Postgres
  include Service

  name :postgres

  props({
    storage: {option: 'storage'},
    instance_type: {option: 'instance_type'},
    multiple_availability_zones: {flag: 'mutliple-az'},
    private: {flag: 'private'}
  })
end

class Redis
  include Service

  name :redis

  props auto_failover: {flag: 'automatic-failover-enabled'},
    instance_type: {option: 'instance-type'},
    cache_cluster_count: {option: 'num-cache-clusters'},
    private: {flag: 'private'}
end
