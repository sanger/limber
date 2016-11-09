# frozen_string_literal: true
# This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2011 Genome Research Ltd.
class Settings
  class << self
    def respond_to?(method, include_private = false)
      super || instance.respond_to?(method, include_private)
    end

    def method_missing(method, *args, &block)
      instance.send(method, *args, &block)
    end
    protected :method_missing

    def configuration_filename
      File.join(File.dirname(__FILE__), '..', 'settings', "#{Rails.env}.yml")
    end
    private :configuration_filename

    def instance
      return @instance if @instance.present?

      @instance = Hashie::Mash.new(YAML.load(eval(ERB.new(File.read(configuration_filename)).src, nil, configuration_filename)))
    rescue => exception
      star_length = [96, 12 + configuration_filename.length].max
      $stderr.puts('*' * star_length)
      $stderr.puts "WARNING! No #{configuration_filename}"
      $stderr.puts "You need to run 'rake config:generate' and can ignore this message if that's what you are doing!"
      $stderr.puts('*' * star_length)
    end
  end
end

Settings.instance
