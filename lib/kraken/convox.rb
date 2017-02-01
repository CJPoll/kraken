module Convox
  def self.apps
    result = `convox apps`
    result
  end

  def self.app_url(app_name, process_type)
    result = `convox apps info #{app_name} | tail -n +5 | grep "(#{process_type})" | head -n 1`
    res = result.split(" ")

    if res.first == "Endpoints"
      return res[1]
    else
      return res.first
    end
  end

  def self.app_running_yet?(app_name)
    result = `convox apps info #{app_name} | grep "Status\s*running"`
    !result.empty?
  end

  def self.create_resource(app_name, resource_type)
    puts "Creating resource"
    system "convox resources create #{resource_type} --name #{Convox.resource_name(app_name, resource_type)}"
  end

  def self.deploy(app_name)
    puts "Deploying #{app_name}"
    system "convox deploy --app #{app_name}"
  end

  def self.has_app?(app_name)
    result = `convox apps | grep #{app_name}`
    !result.empty?
  end

  def self.migrate_database!(app_name, language)
    if language == :ruby
      puts "Migrating DB for #{app_name}"
      `convox run web "bundle exec rake db:migrate" --app #{app_name}`
    else
      raise "Unsupported language to migrate db [#{language}] [#{app_name}]"
    end
  end

  def self.instances
    `convox instances`
  end

  def self.promote(app_name, key)
    puts "Promoting #{app_name}"
    `convox releases promote #{key} --app #{app_name}`
  end

  def self.promotion_key(resp)
    resp.split(/\s/).last.chomp('`')
  end

  def self.proxy(resource_name, port=nil)
    if port
      system "convox resources proxy #{resource_name} --listen #{port} &"
    else
      system "convox resources proxy #{resource_name} &"
    end
    puts "Sleeping for 5 seconds to give time to proxy"
    sleep 5
  end

  def self.resource_name(app_name, resource_type)
    "#{app_name}-#{resource_type}"
  end

  def self.resource_running_yet?(resource_name)
    result = `convox resources info #{resource_name} | grep "Status\s*running"`
    !result.empty?
  end

  def self.set_env(app_name, map)
    kv_pairs = map.map {|k, v| "#{k}=\"#{v.chomp}\""}
    kv_pairs = kv_pairs.join(" ")
    puts "Setting Env for #{app_name} (#{kv_pairs})"

    `convox env set #{kv_pairs} --app #{app_name} --promote`
  end

  def self.watch(&block)
    until result = block.call
      sleep(5)
    end

    result
  end

  def self.resource_url(resource_name)
    `convox resources info #{resource_name} | grep URL | awk '{ print $2 }'`.chomp
  end
end

