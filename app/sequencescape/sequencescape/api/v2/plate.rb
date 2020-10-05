# frozen_string_literal: true

# A plate from sequencescape via the V2 API
class Sequencescape::Api::V2::Plate < Sequencescape::Api::V2::Base
  include Sequencescape::Api::V2::Shared::HasRequests

  self.plate = true
  has_many :wells
  has_many :samples
  has_many :ancestors, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_many :descendants, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_many :parents, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_many :children, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_many :child_plates, class_name: 'Sequencescape::Api::V2::Plate'
  has_many :child_tubes, class_name: 'Sequencescape::Api::V2::Tube'
  has_one :purpose
  has_one :custom_metadatum_collection

  property :created_at, type: :time
  property :updated_at, type: :time
  property :labware_barcode, type: :barcode

  def self.find_by(options)
    Sequencescape::Api::V2.plate_for_presenter(options)
  end

  def self.find_all(options, includes: DEFAULT_INCLUDES)
    Sequencescape::Api::V2::Plate.includes(*includes).where(options).all
  end

  #
  # Override the model used in form/URL helpers
  # to allow us to treat old and new api the same
  #
  # @return [ActiveModel::Name] The resource behaves like a Limber::Plate
  #
  def model_name
    ::ActiveModel::Name.new(Limber::Plate, false)
  end

  # Currently use the uuid as our main identifier, might switch to human barcode soon
  def to_param
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

  def tagged?
    wells.any?(&:tagged?)
  end

  def human_barcode
    labware_barcode.human
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

  def locations_in_rows
    WellHelpers.row_order(size)
  end

  def barcode
    labware_barcode
  end

  def stock_plates(purpose_names: SearchHelper.stock_plate_names)
    @stock_plates ||= stock_plate? ? [self] : ancestors.where(purpose_name: purpose_names)
  end

  def stock_plate
    stock_plates.last
  end

  def workline_identifier
    workline_reference&.barcode&.human
  end

  # This is the plate that will act as a reference in my workflow that will be
  # printed in the label at the top_right field. It is the first stock by default,
  # but in some cases we may want to display a different plate. To change the default
  # selection from stock plate to other plate purpose, we have to modify the purposes.yml
  # config file and add a workline_reference_identifier attribute with the purpose we want to select.
  def workline_reference
    alternative_workline_identifier_purpose = SearchHelper.alternative_workline_reference_name(self)
    return stock_plate if alternative_workline_identifier_purpose.nil?

    ancestors.where(purpose_name: alternative_workline_identifier_purpose).last
  end

  def stock_plate?(purpose_names: SearchHelper.stock_plate_names)
    purpose_names.include?(purpose.name)
  end

  def primer_panels
    active_requests.map(&:primer_panel).compact.uniq
  end

  def primer_panel
    primer_panels.first
  end

  def pools
    @pools ||= generate_pools
  end

  def each_well_and_aliquot
    wells.each do |well|
      well.aliquots.each do |aliquot|
        yield well, aliquot
      end
    end
  end

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
end
