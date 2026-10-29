# frozen_string_literal: true

# Decides which requests the browser may make to Sequencescape via the proxy.
# Paths are relative to the Sequencescape v2 API root, e.g. 'labware/1?include=comments'.
class SequencescapeProxyPolicy
  READ_RESOURCES = %w[
    labware
    plates
    tubes
    tube_racks
    wells
    receptacles
    purposes
    tag_groups
    tag_sets
    comments
    users
    custom_metadatum_collections
    qc_assays
    qc_results
  ].freeze

  # Resources the browser may create or modify, by verb
  WRITE_RESOURCES = {
    'POST' => %w[comments custom_metadatum_collections qc_assays],
    'PATCH' => %w[custom_metadatum_collections]
  }.freeze

  # resource, optional /id, optional nested /relationship, e.g. labware/12/comments
  PATH_FORMAT = %r{\A(?<resource>[a-z_]+)(?:/\d+(?:/[a-z_]+)?)?\z}

  def self.allowed?(method, path)
    new(method, path).allowed?
  end

  def initialize(method, path)
    @method = method.to_s.upcase
    @path = path.to_s
  end

  def allowed?
    resource = parse_resource
    return false if resource.nil?

    case @method
    when 'GET'
      READ_RESOURCES.include?(resource)
    else
      WRITE_RESOURCES.fetch(@method, []).include?(resource)
    end
  end

  private

  # Returns the top-level resource, or nil if the path is not a plain relative API path.
  # The query string is ignored; it is passed on untouched and cannot change the target path.
  def parse_resource
    return nil if @path.include?('%') || @path.include?('\\')

    match = PATH_FORMAT.match(@path.split('?', 2).first)
    match && match[:resource]
  end
end
