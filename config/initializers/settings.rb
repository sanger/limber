class Settings
  include Singleton
  
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
  
  def initialize
    filename    = File.join(File.dirname(__FILE__), *%W[.. settings #{RAILS_ENV}.yml])
    @settings   = YAML.load(eval(ERB.new(File.read(filename)).src, nil, filename))
  end
  
  def respond_to?(method, include_private = false)
    super or is_settings_query_method?(method) or @settings.key?(setting_key_for(method))
  end
  
protected
  
  def method_missing(method, *args, &block)
    setting_key    = setting_key_for(method)
    setting_exists = @settings.key?(setting_key)

    if is_settings_query_method?(method)
      setting_exists
    elsif setting_exists
      @settings[ setting_key ]
    else
      super
    end
  end

private

  def is_settings_query_method?(method)
    method.to_s =~ /\?$/
  end

  def setting_key_for(method)
    method.to_s.match(/^([^\?]+)\??$/)[ 1 ]
  end
  
end

Settings.instance
