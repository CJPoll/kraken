class BadCLIArgumentException < StandardError; end

module Settings
  def self.load!(args)
    @no_deploy = []
    @ignore = []

    while args.length > 0 do
      case args.shift 
      when '--no-deploy'
        @no_deploy << args.shift
      when '--ignore'
        @ignore << args.shift
      else
        raise BadCLIArgumentException
      end
    end
  end

  def self.deploy?(app)
    !(@no_deploy.include?('all') || @no_deploy.include?(app) || @ignore.include?(app))
  end

  def self.ignore?(app)
    @ignore.include?(app)
  end
end
