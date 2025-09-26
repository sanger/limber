# frozen_string_literal: true

require 'config_loader/pipelines_loader'

# Global setting object loaded from `config/settings/_environment_.yml` which is
# generated on running `rake config:generate`
class Settings
  class << self
    def configuration_filename
      Rails.root.join('config', 'settings', "#{Rails.env}.yml")
    end
    private :configuration_filename

    def instance # rubocop:todo Metrics/AbcSize
      return @instance if @instance.present?

      # Ideally we'd do Hashie::Mash.load(File.read(configuration_filename)) here
      # but the creates an immutable setting object that messes with tests.
      # Immutability is good here though, so we should probably fix that.
      # Added flag onto safe_load to allow read of anchors (aliases) in yml files.
      config_file_descriptor = File.open(configuration_filename, 'r:bom|utf-8')
      @instance =
        Hashie::Mash.quiet(:max, :min, :size, :class).new(
          YAML.safe_load(config_file_descriptor, permitted_classes: [Symbol], aliases: true)
        )

      # To view a list of pipeline groups and respective pipelines:
      # e.g. Settings.pipelines.group_by(&:pipeline_group).transform_values { |pipelines| pipelines.map(&:name) }
      @instance.pipelines = ConfigLoader::PipelinesLoader.new.pipelines

      @instance
    rescue Errno::ENOENT
      # This before we've fully initialized and is intended to report issues to
      # the user.
      # rubocop:disable Style/StderrPuts
      star_length = [96, 12 + configuration_filename.to_s.length].max
      $stderr.puts('*' * star_length)
      $stderr.puts "WARNING! No #{configuration_filename}"
      $stderr.puts "You need to run 'rake config:generate' and can ignore this message if that's what you are doing!"
      $stderr.puts('*' * star_length)
      # rubocop:enable Style/StderrPuts
    end

    delegate_missing_to :instance

    def reinitialize
      @instance = nil
      self
    end
  end
end

Rails.application.config.to_prepare do
  # By re-initializing here we gain:
  # - Clear hot-reloading of classes like PipelineList when in development mode
  # - Reloading of the settings in development mode, meaning you don't need to
  #   restart following a rake config:generate
  Settings.reinitialize.instance
end
