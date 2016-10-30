current_dir = File.dirname(__FILE__)
require "#{current_dir}/app"
require 'json'

class Config
  attr_accessor :app, :services

  def initialize(json)
    @app = Application.new
    @app.name = json['app']
    services = json['services'] || []
    @services = services.map do |s_json|
      Service.new(s_json, @app.name)
    end
  end

  def self.load
    file_name = "concker.json"
    json = File.read(file_name)
    config_json = ::JSON.parse(json)
    Config.new(config_json)
  end

  def create
    @app.create
    @services.each do |service|
      service.create
    end
  end
end
