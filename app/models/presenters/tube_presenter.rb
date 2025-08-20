# frozen_string_literal: true

# Basic core presenter for tubes
module Presenters
  class TubePresenter # rubocop:todo Style/Documentation
    include Presenters::Presenter
    include Statemachine::Shared
    include Presenters::CreationBehaviour
    include RobotControlled

    self.summary_items = {
      'Barcode' => :barcode,
      'Tube type' => :purpose_name,
      'Current tube state' => :state,
      'Input plate barcode' => :input_barcode,
      'Created on' => :created_on
    }

    # The state is delegated to the tube
    # Purpose returns the plate or tube purpose of the labware.
    # Currently this needs to be specialised for tube or plate but in future
    # both should use #purpose and we'll be able to share the same method for
    # all presenters.
    delegate :purpose, :state, :human_barcode, to: :labware

    def label
      # fetch label class from purpose if present
      label_class = purpose_config[:label_class] || 'Labels::TubeLabel'
      label_class.constantize.new(labware)
    end

    def sample_count
      labware.aliquots.count
    end

    def tag_sequences
      labware.aliquots.map(&:tag_pair)
    end

    def comment_title
      "#{human_barcode} - #{purpose_name}"
    end

    def custom_metadata_fields
      purpose_config.fetch(:custom_metadata_fields, []).to_a.to_json
    end

    def sequencescape_submission
      return nil if purpose_config[:submission].empty?

      s = SequencescapeSubmission.new(purpose_config[:submission].to_hash.merge(assets: [labware.uuid]))
      yield s if block_given?
      s
    end

    def qc_summary?
      labware.receptacle&.all_latest_qc&.to_a.present?
    end

    def qc_summary
      labware
        .receptacle
        .all_latest_qc
        .sort_by(&:key)
        .each { |result| yield result.key.titleize, result.unit_value.to_s }
    end

    def transfer_volumes?
      !purpose_config[:transfer_parameters].nil?
    end

    def csv_file_links
      purpose_config
        .fetch(:file_links, [])
        .select { |link| can_be_enabled?(link&.states) }
        .map do |link|
          format_extension = link.format || 'csv'
          [
            link.name,
            [
              :limber_tube,
              :tubes_export,
              { id: link.id, limber_tube_id: human_barcode, format: format_extension, **link.params || {} }
            ]
          ]
        end
    end
  end
end
