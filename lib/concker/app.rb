class Application
  attr_accessor :name

  def create
    system "convox apps create #{name} --wait"
  end
end
