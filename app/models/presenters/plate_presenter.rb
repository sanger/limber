# frozen_string_literal: true

require_dependency 'presenters/presenter'

# Basic core presenter class for plates
class Presenters::PlatePresenter
  include Presenters::Presenter
  include PlateWalking
  include Presenters::RobotControlled
  include Presenters::ExtendedCsv

  class_attribute :aliquot_partial, :summary_partial, :well_failure_states

  self.summary_partial = 'labware/plates/standard_summary'
  self.labware_class = :plate
  self.aliquot_partial = 'labware/aliquot'
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
  self.well_failure_states = [:passed]

  # Note: Validation here is intended as a warning. Rather than strict validation
  validates :pcr_cycles_specified, numericality: { less_than_or_equal_to: 1, message: 'is not consistent across the plate.' }

  validates :pcr_cycles,
            inclusion: { in: ->(r) { r.expected_cycles },
                         message: 'differs from standard. %{value} cycles have been requested.' },
            if: :expected_cycles

  validates_with Validators::InProgressValidator

  delegate :tagged?, :width, :height, :size, :plate_purpose, to: :labware

  alias plate_to_walk labware
  # Purpose returns the plate or tube purpose of the labware.
  # Currently this needs to be specialised for tube or plate but in future
  # both should use #purpose and we'll be able to share the same method for
  # all presenters.
  alias purpose plate_purpose

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
    Labels::PlateLabel.new(labware)
  end

  def tube_labels
    labware.tubes.map { |t| Labels::TubeLabel.new(t) }
  end

  def suitable_labware
    yield
  end

  def control_library_passing
    yield if allow_library_passing? && !suggest_library_passing?
  end

  def control_suggested_library_passing
    yield if allow_library_passing? && suggest_library_passing?
  end

  def suggest_library_passing?
    purpose_config[:suggest_library_pass_for]&.include?(active_request_type)
  end

  def control_tube_display
    yield if labware.transfers_to_tubes?
  end

  def labware_form_details(view)
    { url: view.limber_plate_path(labware), as: :plate }
  end

  def transfers
    transfers = labware.creation_transfer.transfers
    transfers.sort { |a, b| split_location(a.first) <=> split_location(b.first) }
  end

  def csv_file_links
    [['', "#{Rails.application.routes.url_helpers.limber_plate_path(labware.uuid)}.csv"]]
  end

  def filename(offset = nil)
    "#{labware.barcode.prefix}#{labware.barcode.number}#{offset}.csv".tr(' ', '_')
  end

  def prepare
    labware.populate_wells_with_pool
  end

  def tag_sequences
    @tag_sequences ||= labware.wells.each_with_object([]) do |well, tags|
      well.aliquots.each do |aliquot|
        tags << [aliquot.tag.try(:oligo), aliquot.tag2.try(:oligo)]
      end
    end
  end

  private

  def number_of_filled_wells
    labware.wells.count { |w| w.aliquots.present? }
  end

  def pcr_cycles_specified
    cycles.length
  end

  def cycles
    labware.pcr_cycles
  end

  # Split a location string into an array containing the row letter
  # and the column number (as a integer) so that they can be sorted.
  def split_location(location)
    match = location.match(/^([A-H])(\d+)/)
    [match[2].to_i, match[1]] # Order by column first
  end

  def active_request_type
    return :none if labware.pools.empty?
    labware.pools.values.first['request_type']
  end
end
