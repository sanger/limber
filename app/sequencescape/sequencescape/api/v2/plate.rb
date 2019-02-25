# frozen_string_literal: true

class Sequencescape::Api::V2::Plate < Sequencescape::Api::V2::Base
  self.plate = true
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

  DEFAULT_INCLUDES = [
    :purpose,
    { wells: [
      :downstream_assets,
      {
        requests_as_source: %w[request_type primer_panel pre_capture_pool],
        aliquots: ['sample', { request: %w[request_type primer_panel pre_capture_pool] }]
      }
    ] }
  ].freeze

  def self.find_by(options, includes: DEFAULT_INCLUDES)
    Sequencescape::Api::V2::Plate.includes(*includes).find(options).first
  end

  def self.find_all(options, includes: DEFAULT_INCLUDES)
    Sequencescape::Api::V2::Plate.includes(*includes).find(options).all
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

  # Currently us the uuid as our main identifier, might switch to human barcode soon
  def to_param
    uuid
  end

  def active_requests
    @active_requests ||= wells.flat_map(&:active_requests)
  end

  def submissions
    active_requests.map { |request| request.submission&.uuid }.uniq
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
    active_requests.any?(&:for_multiplexing)
  end

  def ready_for_custom_pooling?
    any_complete_requests? || ready_for_automatic_pooling?
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
    @stock_plate ||= if stock_plate?
                       self
                     else
                       ancestors.where(purpose_name: purpose_names).last
                     end
  end

  def stock_plate?(purpose_names: SearchHelper.stock_plate_names)
    purpose_names.include?(purpose.name)
  end

  def pcr_cycles
    active_requests.map(&:pcr_cycles).compact.uniq
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

  def role
    wells.detect(&:role)&.role
  end

  def priority
    wells.map(&:priority).max || 0
  end

  private

  def generate_pools
    Pools.new(wells_in_columns)
  end
end
