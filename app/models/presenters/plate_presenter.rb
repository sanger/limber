# frozen_string_literal: true

require_dependency 'presenters/presenter'

class Presenters::PlatePresenter
  include Presenters::Presenter
  include PlateWalking
  include Presenters::RobotControlled
  include Presenters::ExtendedCsv

  attr_accessor :api, :labware
  self.attributes = %i[api labware]

  class_attribute :labware_class, :aliquot_partial, :summary_partial
  self.labware_class = :plate
  self.aliquot_partial = 'labware/aliquot'
  self.summary_partial = 'labware/plates/standard_summary'

  # summary_items is a hash of a label label, and a symbol representing the
  # method to call to get the value
  class_attribute :summary_items
  self.summary_items = {
    'Barcode' => :barcode,
    'Number of wells' => :number_of_wells,
    'Plate type' => :purpose_name,
    'Current plate state' => :state,
    'Input plate barcode' => :input_barcode,
    'PCR Cycles' => :pcr_cycles,
    'Created on' => :created_on
  }

  # This is now generated dynamically by the LabwareHelper
  class_attribute :tab_states

  class_attribute :well_failure_states
  self.well_failure_states = [:passed]

  # Note: Validation here is intended as a warning. Rather than strict validation
  validates :pcr_cycles_specified, numericality: { less_than_or_equal_to: 1, message: 'is not consistent across the plate.' }

  validates :pcr_cycles,
            inclusion: { in: ->(r) { r.expected_cycles },
                         message: 'differs from standard. %{value} cycles have been requested.' },
            if: :expected_cycles

  validates_with Validators::SuboptimalValidator

  alias plate labware
  alias plate_to_walk labware

  def number_of_wells
    "#{number_of_filled_wells}/#{total_number_of_wells}"
  end

  def pcr_cycles
    if pcr_cycles_specified.zero?
      'No pools specified'
    else
      cycles.to_sentence
    end
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
    yield if allow_library_passing?
  end

  def tagged?
    first_filled_well = labware.wells.detect { |w| w.aliquots.first }
    first_filled_well && first_filled_well.aliquots.first.tag.identifier.present?
  end

  def control_tube_display
    yield if labware.transfers_to_tubes?
  end

  # Purpose returns the plate or tube purpose of the labware.
  # Currently this needs to be specialised for tube or plate but in future
  # both should use #purpose and we'll be able to share the same method for
  # all presenters.
  def purpose
    labware.plate_purpose
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

  private

  def number_of_filled_wells
    plate.wells.count { |w| w.aliquots.present? }
  end

  def total_number_of_wells
    plate.size
  end

  def pcr_cycles_specified
    cycles.length
  end

  def cycles
    plate.pcr_cycles
  end

  # Split a location string into an array containing the row letter
  # and the column number (as a integer) so that they can be sorted.
  def split_location(location)
    match = location.match(/^([A-H])(\d+)/)
    [match[2].to_i, match[1]] # Order by column first
  end
end
