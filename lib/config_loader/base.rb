# frozen_string_literal: true

# Provides tools for loading configs from a given folder
module ConfigLoader
  # Inherit from ConfigLoader base to automatically load one or more yaml files
  # into a @config hash. Config folders are found in config/
  # and each loader should specify its own subfolder by setting the config_folder
  # class attribute.
  class Base
    BASE_CONFIG_PATH = %w[config].freeze
    EXTENSION = '.yml'
    WIP_EXTENSION = '.wip.yml'

    class_attribute :config_folder

    #
    # Create a new config loader from yaml files
    #
    # @param files [Array,NilClass] pass in an array of files to load, or nil to load all files.
    # @param directory [Pathname, String] The directory from which to load the files.
    #   defaults to config/default_records/plate_purposes
    #
    def initialize(files: nil, directory: default_path)
      path = directory.is_a?(Pathname) ? directory : Pathname.new(directory)

      @files = path.children.select { |child| should_include_file?(files, child) }
      load_config
    end

    private

    def should_include_file?(files, child)
      yaml?(child) && in_list?(files, child) &&
        (!work_in_progress?(child) || (work_in_progress?(child) && deploy_wip_pipelines))
    end

    def deploy_wip_pipelines
      Limber::Application.config.try(:deploy_wip_pipelines) || false
    end

    #
    # Returns true if filename is a yaml file.
    #
    # @param [Pathname] filename The file to be checked
    #
    # @return [Bool] returns true if the file is a yaml file, false otherwise
    #
    def yaml?(filename)
      filename.extname == EXTENSION
    end

    def default_path
      Rails.root.join(*BASE_CONFIG_PATH, config_folder)
    end

    def in_list?(list, file)
      (list.nil? || list.include?(file.basename(EXTENSION).to_s))
    end

    def work_in_progress?(filename)
      filename.to_s.end_with?(WIP_EXTENSION)
    end

    #
    # Load the appropriate configuration files into @config
    #
    def load_config
      @config =
        @files.each_with_object({}) do |file, store|
          latest_file = YAML.load_file(file)
          if latest_file.nil?
            warn "Cannot parse file: #{file}"
          else
            check_duplicates(store.keys, latest_file.keys)
            store.merge!(latest_file)
          end
        end
    end

    def check_duplicates(stored_keys, new_keys)
      duplicate_keys = stored_keys & new_keys
      return if duplicate_keys.blank?

      raise StandardError, "Keys #{duplicate_keys} appear in multiple files in #{default_path}"
    end
  end
end
