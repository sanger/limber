class Settings
  class << self
    def respond_to?(method, include_private = false)
      super or self.instance.respond_to?(method, include_private)
    end

    def method_missing(method, *args, &block)
      self.instance.send(method, *args, &block)
    end
    protected :method_missing

    def configuration_filename
      File.join(File.dirname(__FILE__), *%W[.. settings #{Rails.env}.yml])
    end
    private :configuration_filename

    def instance
      return @instance if @instance.present?

      @instance = Hashie::Mash.new(YAML.load(eval(ERB.new(File.read(configuration_filename)).src, nil, configuration_filename)))
    rescue => exception
      star_length = [ 96, 12+configuration_filename.length ].max
      $stderr.puts('*'*star_length)
      $stderr.puts "WARNING! No #{configuration_filename}"
      $stderr.puts "You need to run 'rake config:generate' and can ignore this message if that's what you are doing!"
      $stderr.puts('*'*star_length)
    end
  end
end

Settings.instance
