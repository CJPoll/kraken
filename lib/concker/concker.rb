#! /usr/bin/env ruby

current_dir = File.dirname(__FILE__)

require 'json'
require "#{current_dir}/concker/config"

def main
  file_name = "concker.json"
  json = File.read(file_name)
  config_map = JSON.parse(json)
  config = Config.new(config_map)
  puts config.app.name
end

main
