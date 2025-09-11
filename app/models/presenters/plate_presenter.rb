# frozen_string_literal: true

require_dependency 'presenters/presenter'

module Presenters
  # Basic core presenter class for plates
  # Handles the display of plates in the view, not used directly
  # rubocop:disable Metrics/ClassLength
  class PlatePresenter
    include Presenters::Presenter
    include PlateWalking
    include Presenters::RobotControlled
    include Presenters::ExtendedCsv
    include Presenters::CreationBehaviour

    class_attribute :aliquot_partial, :allow_well_failure_in_states, :style_class, :samples_partial

    POOLING_TAB_PATH = 'plates/pooling_tab'

    self.summary_partial = 'labware/plates/standard_summary'
    self.aliquot_partial = 'standard_aliquot'
    self.samples_partial = 'plates/samples_tab'

    # Initializes `summary_items` with a hash mapping display names to their corresponding plate attributes.
    # Used by the summary panel to display information about the plate in the GUI.
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
              length: {
                maximum: 1,
                message: 'are not consistent across the plate.' # rubocop:todo Rails/I18nLocaleTexts
              },
              unless: :multiple_requests_per_well?

    validates :requested_pcr_cycles,
              inclusion: {
                in: ->(r) { r.expected_cycles },
                message: 'differs from standard. %<value>s cycles have been requested.' # rubocop:todo Rails/I18nLocaleTexts
              },
              if: :expected_cycles

    validates_with Validators::InProgressValidator
    validates_with Validators::FailedValidator

    delegate :pcr_cycles,
             :tagged?,
             :number_of_columns,
             :number_of_rows,
             :size,
             :purpose,
             :human_barcode,
             :priority,
             :pools,
             to: :labware
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
      @tubes_and_sources ||= Presenters::TubesWithSources.build(wells:, pools:)
      yield(@tubes_and_sources) if block_given? && @tubes_and_sources.tubes?
      @tubes_and_sources
    end

    def child_plates
      labware.child_plates.tap { |child_plates| yield child_plates if block_given? && child_plates.present? }
    end

    alias child_assets child_plates

    # Returns the CSV file links for the plate based on the configured states.
    #
    # @return [Array<Array<String, Array>>] the CSV file links
    def csv_file_links
      links =
        purpose_config
          .fetch(:file_links, [])
          .select { |link| can_be_enabled?(link&.states) }
          .map do |link|
            [link.name, [:plate, :export, { id: link.id, plate_id: human_barcode, format: :csv, **link.params || {} }]]
          end
      links << ['Download Worksheet CSV', { format: :csv }] if csv.present?
      links
    end

    def filename(offset = nil)
      "#{human_barcode}#{offset}.csv".tr(' ', '_')
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

    def custom_metadata_fields
      purpose_config.fetch(:custom_metadata_fields, []).to_a.to_json
    end

    def quadrants_helper
      size == 384 ? 'quadrant_helper' : 'none'
    end

    def well_failing_applicable?
      allow_well_failure_in_states.include?(state.to_sym)
    end

    def mark_under_represented_wells?
      purpose_config.fetch(:mark_under_represented_wells, false)
    end

    def qc_thresholds
      @qc_thresholds ||= Presenters::QcThresholdPresenter.new(labware, purpose_config.fetch(:qc_thresholds, {}))
    end

    # Determine if we should display the pooling tab in the Presenter views
    # See partial _common_tabbed_pages.html.erb
    def show_pooling_tab?
      # if pooling_tab field is present, show the tab (allows override)
      return true if pooling_tab.present?

      # if the labware has a multiplexing submission order, show the pooling tab
      if labware_is_multiplexed
        self.pooling_tab = POOLING_TAB_PATH
        return true
      end

      # do not show the pooling tab by default
      false
    end

    # This method checks if the labware is in a state that allows manual transfer.
    # It prevents the button appearing if the labware is not in one of the states listed.
    #
    # To use it add an entry to the purpose configuration as follows:
    # :manual_transfer:
    #   states:
    #     - 'started'
    #
    # If no states are defined, it will return true by default.
    def display_manual_transfer_button?
      can_be_enabled?(purpose_config.dig(:manual_transfer, :states))
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
      wells.flat_map { |well| well.requests_in_progress.select(&:passable?).map(&:request_type) }
    end

    # This is determined in Sequencescape by accessing the submission orders and checking if any of them are
    # multiplexed
    def labware_is_multiplexed
      @labware_is_multiplexed ||= labware.active_requests.map(&:submission).uniq&.first&.multiplexed? || false
    end
  end
  # rubocop:enable Metrics/ClassLength
end
