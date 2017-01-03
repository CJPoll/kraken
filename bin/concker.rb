#! /usr/bin/env ruby

current_dir = File.realdirpath(__FILE__)
puts current_dir

require "#{current_dir}/../../lib/concker/config"

module Settings
  def self.deploy?
    !ARGV.include?("--no-deploy")
  end
end

def main
  config = Config.load

  config.create
end

main
