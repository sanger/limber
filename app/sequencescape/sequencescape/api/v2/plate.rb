# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class Sequencescape::Api::V2::Plate < Sequencescape::Api::V2::Base # rubocop:todo Style/Documentation
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

  def active_requests
    @active_requests ||= wells.flat_map(&:active_requests)
  end

  def in_progress_submission_uuids(request_type_key: nil)
    wells.flat_map { |w| w.in_progress_submission_uuids(request_type_key: request_type_key) }.uniq
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

  def each_well_and_aliquot
    wells.each do |well|
      well.aliquots.each do |aliquot|
        yield well, aliquot
      end
    end
  end

  private

  def generate_pools
    Pools.new(wells_in_columns)
  end
end
# rubocop:enable Metrics/ClassLength
