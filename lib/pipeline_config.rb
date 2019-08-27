# frozen_string_literal: true

# This is used as part of a rake task, and will be run within a console.
class PipelineConfig
  attr_reader :name, :options
  class_attribute :default_options

  # TODO: use this version passing in all request and library types
  # def self.load(name, options, all_purposes, all_request_types, all_library_types)
  #   PipelineConfig.new(name, options, all_purposes, all_request_types, all_library_types)
  # end

  def self.load(name, options, all_purposes)
    PipelineConfig.new(name, options, all_purposes)
  end

  self.default_options = {}.tap do |options|
    options[:filters] = { request_type_key: [], library_type: [] }
    # TODO: add relationships (decide on structure, may need arrays)
  end

  # TODO: use this version
  # def initialize(name, options, all_purposes, all_request_types, all_library_types)
  #   @name = name
  #   @options = options
  #   @all_purposes = all_purposes
  #   @all_request_types = all_request_types
  #   @all_library_types = all_library_types
  # end

  def initialize(name, options, all_purposes)
    @name = name
    @options = options
    @all_purposes = all_purposes
  end

  # ---
  # Limber Bespoke Chromium 3pv2:
  #   :filters:
  #     :request_type_key:
  #     - limber_chromium_bespoke
  #     - limber_multiplexing
  #     :library_type:
  #     - Chromium single cell 3 prime v2
  #   :relationships:
  #     LBB Cherrypick: LBB Chromium Tagged
  #     LBB Chromium Tagged: LBB Lib-XP
  #     LBB Lib-XP: LBB Lib Pool Stock
  #     LBB Lib Pool Stock: LB Lib Pool Norm

  def config
    {
      name: name,
      # filters: default_options[:filters]
      filters: filter_options
      # TODO: add in relationships here, with warnings check against all_purposes to check they exist
    }.merge(@options)
  end

  # TODO: we need to check all request type keys in the filters are real request type keys and WARN if not
  # TODO: we need to check all library type names in the filters are real library type names and WARN if not
  # TODO: we need to check all plate/tube purposes are real purpose names and WARN if not

  private

  def filter_options
    return default_options[:filters] if @options[:filters].nil?

    {
      request_type_key: request_type_options,
      library_type: library_type_options
    }
  end

  def request_type_options
    return default_options[:filters][:request_type_key] if @options[:filters][:request_type_key].nil?

    @options[:filters][:request_type_key].each do |key|
      # TODO: better to use passed in list of all request types rather than individual selects here
      warn "WARN: Do not recognise request type key: #{key}" if Sequencescape::Api::V2::RequestType.where(key: key).first.nil?
    end
  end

  def library_type_options
    return default_options[:filters][:library_type] if @options[:filters][:library_type].nil?

    # TODO: check these in similar fashion to request types and warn if not matching
    @options[:filters][:library_type]
    # @options[:filters][:library_type].each do |name|
    #   # Sequencescape::Api::V2::RequestType.find
    #   warn "WARN: Do not recognise library type name: #{name}" if @all_library_types[name].nil?
    # end
  end

  # TODO: add relationships method here to check purposes used exist
end
