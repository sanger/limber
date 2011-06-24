class Settings
  class << self
    def respond_to?(method, include_private = false)
      super or self.instance.respond_to?(method, include_private)
    end

  protected

    def method_missing(method, *args, &block)
      return super unless self.instance.respond_to?(method)
      self.instance.send(method, *args, &block)
    end

  end

  def self.instance
    return @instance if @instance.present?

    filename  = File.join(File.dirname(__FILE__), *%W[.. settings #{Rails.env}.yml])
    @instance = Hashie::Mash.new(YAML.load(eval(ERB.new(File.read(filename)).src, nil, filename)))
  end
end

Settings.instance
