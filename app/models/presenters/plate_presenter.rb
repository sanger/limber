# frozen_string_literal: true

require_dependency 'presenters/presenter'

module Presenters
  # Basic core presenter class for plates
  # Handles the display of plates in the view, not used directly
  class PlatePresenter
    include Presenters::Presenter
    include PlateWalking
    include Presenters::RobotControlled
    include Presenters::ExtendedCsv
    include Presenters::CreationBehaviour

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
      'PCR Cycles' => :requested_pcr_cycles,
      'Created on' => :created_on
    }
    self.allow_well_failure_in_states = [:passed]
    self.style_class = 'standard'

    # @note Validation here is intended as a warning. Rather than strict validation
    validates :pcr_cycles,
              length: { maximum: 1, message: 'are not consistent across the plate.' },
              unless: :multiple_requests_per_well?

    validates :requested_pcr_cycles,
              inclusion: { in: ->(r) { r.expected_cycles },
                           message: 'differs from standard. %<value>s cycles have been requested.' },
              if: :expected_cycles

    validates_with Validators::InProgressValidator
    validates_with Validators::FailedValidator

    delegate :pcr_cycles, :tagged?, :number_of_columns, :number_of_rows, :size,
             :purpose, :human_barcode, :priority, :pools, to: :labware
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

    def requested_pcr_cycles
      pcr_cycles.empty? ? 'No pools specified' : pcr_cycles.to_sentence
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

    alias child_assets child_plates

    def csv_file_links
      links = purpose_config.fetch(:file_links, []).map do |link|
        [
          link.name,
          [:limber_plate, :export, { id: link.id, limber_plate_id: human_barcode, format: :csv, **link.params || {} }]
        ]
      end
      links << ['Download Worksheet CSV', { format: :csv }] if csv.present?
      links
    end

    def filename(offset = nil)
      "#{labware.barcode.prefix}#{labware.barcode.number}#{offset}.csv".tr(' ', '_')
    end

    def tag_sequences
      wells.flat_map { |well| well.aliquots.map(&:tag_pair) }
    end

    def wells
      labware.wells_in_columns
    end

    def comment_title
      "#{human_barcode} - #{purpose_name}"
    end

    def quadrants_helper
      size == 384 ? 'quadrant_helper' : 'none'
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

    # Passable requests are those associated with aliquots,
    # which have not yet been passed, failed or cancelled
    def passable_request_types
      wells.flat_map do |well|
        well.requests_in_progress.select(&:passable?).map(&:request_type_key)
      end
    end
  end
end
