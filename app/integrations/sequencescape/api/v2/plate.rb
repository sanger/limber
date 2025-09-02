# frozen_string_literal: true

require_dependency 'well_helpers'

# A plate from sequencescape via the V2 API
# rubocop:disable Metrics/ClassLength
class Sequencescape::Api::V2::Plate < Sequencescape::Api::V2::Base
  include WellHelpers::Extensions
  include Sequencescape::Api::V2::Shared::HasRequests
  include Sequencescape::Api::V2::Shared::HasPurpose
  include Sequencescape::Api::V2::Shared::HasBarcode
  include Sequencescape::Api::V2::Shared::HasWorklineIdentifier
  include Sequencescape::Api::V2::Shared::HasQcFiles

  UNKNOWN = 'Unknown'

  DEFAULT_INCLUDES = [
    :purpose,
    { wells: [requests_as_source: %i[primer_panel], aliquots: [request: %i[primer_panel request_type]]] }
  ].freeze

  self.plate = true
  has_many :wells
  has_many :samples
  has_many :ancestors, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_many :descendants, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_many :parents, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_many :children, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_many :direct_submissions, class_name: 'Sequencescape::Api::V2::Submission'
  has_many :state_changes
  has_many :submission_pools, class_name: 'Sequencescape::Api::V2::SubmissionPool'
  has_many :transfers_as_destination, class_name: 'Sequencescape::Api::V2::Transfer'
  has_one :custom_metadatum_collection

  property :created_at, type: :time
  property :updated_at, type: :time

  def self.find_by(options)
    Sequencescape::Api::V2.plate_for_presenter(**options)
  end

  def self.find_all(options, includes: DEFAULT_INCLUDES, paginate: {})
    Sequencescape::Api::V2::Plate.includes(*includes).where(**options).paginate(paginate).all
  end

  # Override the model used in form/URL helpers
  # to allow us to treat old and new api the same
  # @return [ActiveModel::Name] The resource behaves like a Plate
  #
  def model_name
    ::ActiveModel::Name.new(Plate, false)
  end

  # Overrides the Rails method to return the UUID of the labware for use in URL generation.
  #
  # @return [String] The UUID of the labware instance.
  def to_param
    # Currently use the uuid as our main identifier, might switch to human barcode soon
    uuid
  end

  # @note JG 17/09/2020
  # Active requests are determined on a per-well level
  # This is to maintain pre-existing behaviour. What this means:
  # In progress requests (those not passed or failed) take precedence over
  # those which are passed/failed.
  # Currently: This happens on a per-well level, which means if well A1
  # only has completed requests, and yet B1 has in-progress requests out of
  # it, then both A1s completed requests, and B1s in progress requests will
  # be listed.
  # Alternatively: Remove this and even a single in progress request for
  # any well will take precedence. In theory this probably makes more sense
  # but in practice we tend to operate on the plate as a whole.
  def active_requests
    @active_requests ||= wells.flat_map(&:active_requests)
  end

  def wells_in_columns
    @wells_in_columns ||= wells.sort_by(&:coordinate)
  end

  # Returns wells sorted by rows first and then columns.
  # @return [Array<Well>] The wells sorted in row-major order.
  def wells_in_rows
    @wells_in_rows ||= wells.sort_by { |well| [well.coordinate[1], well.coordinate[0]] }
  end

  # Returns the well at a specified location.
  # @param well_location [String] The location to find the well at.
  # @return [Well, nil] The well at the specified location, or `nil` if no
  #   well is found at that location.
  def well_at_location(well_location)
    wells.detect { |well| well.location == well_location }
  end

  def number_of_pools
    pooling_metadata.length
  end

  def library_type_name
    return UNKNOWN if first_pool.nil?

    first_pool.dig('library_type', 'name') || UNKNOWN
  end

  def insert_size
    return UNKNOWN if first_pool.nil?

    first_pool.fetch('insert_size', [UNKNOWN]).to_a.join(' ')
  end

  # A number of attributes should be consistent across the plate.
  # The example pool provides a source of this information.
  # Note that if this assumption no longer holds true, this will need updating.
  def first_pool
    pooling_metadata.values.first
  end

  def tagged?
    wells.any?(&:tagged?)
  end

  def ready_for_automatic_pooling?
    for_multiplexing
  end

  def ready_for_custom_pooling?
    any_complete_requests? || ready_for_automatic_pooling?
  end

  def size
    number_of_rows * number_of_columns
  end

  def fetch_stock_plate_ancestors(purpose_names: SearchHelper.stock_plate_names)
    ancestors.where(purpose_name: purpose_names)
  end

  def stock_plate
    return self if stock_plate?

    # Note that it's only when we call last that we get an actual object to cache.
    # If we cache the query to the API, then it will still be made every time we call stock_plate.
    @stock_plate ||= fetch_stock_plate_ancestors.order(id: :asc).last
  end

  def stock_plate?(purpose_names: SearchHelper.stock_plate_names)
    purpose_names.include?(purpose_name)
  end

  def primer_panels
    active_requests.map(&:primer_panel).filter_map.uniq
  end

  def primer_panel
    primer_panels.first
  end

  def pools
    @pools ||= generate_pools
  end

  def each_well_and_aliquot
    wells.each { |well| well.aliquots.each { |aliquot| yield well, aliquot } }
  end

  def assign_pools_to_wells
    pooled_wells = pooling_metadata.values.pluck('wells')
    wells.each do |well|
      pool = pooled_wells.find { |wells| wells.include?(well.location) }
      next if pool.nil?

      well.pool = pool
    end
  end

  def purpose_config
    Settings.purposes[purpose&.uuid] || {}
  end

  # return true if the plate has register_stock_plate flag in config file
  def register_stock_plate?
    purpose_config.fetch(:register_stock_plate, false)
  end

  # This method is used to register the stock plate in Sequencescape.
  custom_endpoint :register_stock_for_plate, on: :member, request_method: :post

  private

  def aliquots
    wells.flat_map(&:aliquots)
  end

  def requests_as_source
    wells.flat_map(&:requests_as_source)
  end

  def generate_pools
    Pools.new(wells_in_columns)
  end
  # rubocop:enable Metrics/ClassLength
end
