# frozen_string_literal: true

class Sequencescape::Api::V2::Plate < Sequencescape::Api::V2::Base
  has_many :wells
  has_many :samples
  has_many :ancestors, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_many :descendants, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_many :parents, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_many :children, class_name: 'Sequencescape::Api::V2::Asset' # Having issues with polymorphism, temporary class
  has_one :purpose

  property :created_at, type: :time
  property :updated_at, type: :time
  property :labware_barcode, type: :barcode

  #
  # Override the model used in form/URL helpers
  # to allow us to treat old and new api the same
  #
  # @return [ActiveModel::Name] The resource behaves like a Limber::Plate
  #
  def model_name
    ::ActiveModel::Name.new(Limber::Plate, false)
  end

  # Currently us the uuid as out main identifier, might witch to human barcode soon
  def to_param
    uuid
  end

  def wells_in_columns
    @wells_in_columns ||= wells.sort_by { |w| WellHelpers.well_coordinate(w.position['name']) }
  end

  def tagged?
    wells.any?(&:tagged?)
  end

  def plate?
    true
  end

  def tube?
    false
  end

  def human_barcode
    labware_barcode.human
  end

  def ready_for_automatic_pooling?
    active_requests.any?(&:for_multiplexing)
  end

  def any_complete_requests?
    active_requests.any?(&:passed?)
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

  def stock_plate(purpose_names: SearchHelper.stock_plate_names)
    if stock_plate?
      self
    else
      ancestors.where(purpose_name: purpose_names).last
    end
  end

  def stock_plate?(purpose_names: SearchHelper.stock_plate_names)
    purpose_names.include?(purpose.name)
  end

  def transfers_to_tubes?
    false # TODO: Add the right logic
  end

  def pcr_cycles
    active_requests.map(&:pcr_cycles).uniq
  end

  def active_requests
    wells.flat_map(&:active_requests)
  end

  def primer_panels
    active_requests.map(&:primer_panel).uniq
  end

  def primer_panel
    primer_panels.first
  end

  # TODO: Remove this
  def pools
    []
  end

  def role
    wells.detect(&:role)&.role
  end

  def priority
    wells.map(&:priority).max || 0
  end

  deprecate def height
    number_of_rows
  end

  deprecate def width
    number_of_columns
  end
end
