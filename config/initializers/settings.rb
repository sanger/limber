# frozen_string_literal: true

# This is used as part of a take task, and will be run within a console.
# rubocop:disable Style/StderrPuts
class Settings
  class << self
    def configuration_filename
      Rails.root.join('config', 'settings', "#{Rails.env}.yml")
    end
    private :configuration_filename

    def instance
      return @instance if @instance.present?

      # Ideally we'd do Hashie::Mash.load(File.read(configuration_filename)) here
      # but the creates an immutable setting object that messes with tests.
      # Immutability is good here though, so we should probably fix that.
      # Added flag onto safe_load to allow read of anchors (aliases) in yml files.
      @instance = Hashie::Mash.new(YAML.safe_load(File.read(configuration_filename), [Symbol], [], true))
    rescue Errno::ENOENT
      star_length = [96, 12 + configuration_filename.to_s.length].max
      $stderr.puts('*' * star_length)
      $stderr.puts "WARNING! No #{configuration_filename}"
      $stderr.puts "You need to run 'rake config:generate' and can ignore this message if that's what you are doing!"
      $stderr.puts('*' * star_length)
    end

    delegate_missing_to :instance
  end
end

Settings.instance
# rubocop:enable Style/StderrPuts
