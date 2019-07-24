# frozen_string_literal: true

require_dependency 'presenters/presenter'

# Basic core presenter class for plates
class Presenters::PlatePresenter
  include Presenters::Presenter
  include PlateWalking
  include Presenters::RobotControlled
  include Presenters::ExtendedCsv

  class_attribute :aliquot_partial, :summary_partial, :allow_well_failure_in_states, :style_class

  self.summary_partial = 'labware/plates/standard_summary'
  self.aliquot_partial = 'standard_aliquot'
  # summary_items is a hash of a label label, and a symbol representing the
  # method to call to get the value
  self.summary_items = {
    'Barcode' => :barcode,
    'Number of wells' => :number_of_wells,
    'Plate type' => :purpose_name,
    'Current plate state' => :state,
    'Input plate barcode' => :input_barcode,
    'PCR Cycles' => :pcr_cycles,
    'Created on' => :created_on
  }
  self.allow_well_failure_in_states = [:passed]
  self.style_class = 'standard'

  # Note: Validation here is intended as a warning. Rather than strict validation
  validates :pcr_cycles_specified,
            numericality: { less_than_or_equal_to: 1, message: 'is not consistent across the plate.' },
            unless: :multiple_requests_per_well?

  validates :pcr_cycles,
            inclusion: { in: ->(r) { r.expected_cycles },
                         message: 'differs from standard. %{value} cycles have been requested.' },
            if: :expected_cycles

  validates_with Validators::InProgressValidator

  delegate :tagged?, :number_of_columns, :number_of_rows, :size, :purpose, :human_barcode, :priority, :pools, to: :labware
  delegate :pool_index, to: :pools
  delegate :tube_labels, to: :tubes_and_sources

  alias plate_to_walk labware
  # Purpose returns the plate or tube purpose of the labware.
  # Currently this needs to be specialised for tube or plate but in future
  # both should use #purpose and we'll be able to share the same method for
  # all presenters.
  alias plate_purpose purpose

  def number_of_wells
    "#{number_of_filled_wells}/#{size}"
  end

  def pcr_cycles
    pcr_cycles_specified.zero? ? 'No pools specified' : cycles.to_sentence
  end

  def expected_cycles
    purpose_config.dig(:warnings, :pcr_cycles_not_in)
  end

  def label
    label_class = purpose_config.fetch(:label_class)
    label_class.constantize.new(labware)
  end

  def tubes_and_sources
    @tubes_and_sources ||= Presenters::TubesWithSources.build(wells: wells, pools: pools)
    yield(@tubes_and_sources) if block_given? && @tubes_and_sources.tubes?
    @tubes_and_sources
  end

  def child_plates
    labware.child_plates.tap do |child_plates|
      yield child_plates if block_given? && child_plates.present?
    end
  end

  def csv_file_links
    links = []
    if purpose_config.present? && purpose_config.file_links.present?
      purpose_config.file_links.each do |link|
        links << [link.name, [:limber_plate, :export, { id: link.id, limber_plate_id: human_barcode, format: :csv }]]
      end
    end
    links << ['Download Worksheet CSV', { format: :csv }] if csv.present?
    links
  end

  def filename(offset = nil)
    "#{labware.barcode.prefix}#{labware.barcode.number}#{offset}.csv".tr(' ', '_')
  end

  def tag_sequences
    @tag_sequences ||= wells.each_with_object([]) do |well, tags|
      well.aliquots.each do |aliquot|
        tags << [aliquot.tag_oligo, aliquot.tag2_oligo]
      end
    end
  end

  def wells
    labware.wells_in_columns
  end

  def comment_title
    "#{human_barcode} - #{purpose_name}"
  end

  private

  def libraries_passable?
    tagged? && passable_request_types.present?
  end

  def multiple_requests_per_well?
    wells.any?(&:multiple_requests?)
  end

  def number_of_filled_wells
    wells.count { |w| w.aliquots.present? }
  end

  def pcr_cycles_specified
    cycles.length
  end

  def cycles
    labware.pcr_cycles
  end

  # Passable requests are those associated with aliquots,
  # which have not yet been passed, failed or cancelled
  def passable_request_types
    wells.flat_map do |well|
      well.requests_in_progress.select(&:passable?).map(&:request_type_key)
    end
  end

  def active_request_types
    wells.flat_map do |well|
      well.active_requests.map(&:request_type_key)
    end
  end

  # Active requests may or may not have library types
  def active_library_types
    wells.flat_map do |well|
      well.active_requests.each_with_object([]) do |req, library_type_names|
        library_type_names << req.library_type unless req.library_type.nil?
      end
    end
  end
end
