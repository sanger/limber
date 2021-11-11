# frozen_string_literal: true

# Basic core presenter for tubes
module Presenters
  class TubePresenter # rubocop:todo Style/Documentation
    include Presenters::Presenter
    include Statemachine::Shared
    include Presenters::CreationBehaviour
    include TransfersHelper
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
      Labels::TubeLabel.new(labware)
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

    def sequencescape_submission
      return nil if purpose_config.submission.empty?

      s = SequencescapeSubmission.new(purpose_config.submission.to_hash.merge(assets: [labware.uuid]))
      yield s if block_given?
      s
    end

    def child_plates
      labware.child_plates.tap do |child_plates|
        yield child_plates if block_given? && child_plates.present?
      end
    end

    alias child_assets child_plates

    def tubes_and_sources
      labware.child_tubes.tap do |child_tubes|
        yield child_tubes if block_given? && child_tubes.present?
      end
    end

    def qc_summary?
      labware.receptacle&.qc_results&.to_a.present?
    end

    def qc_summary
      labware.receptacle.qc_results.sort_by(&:key).each do |result|
        yield result.key.titleize, result.unit_value
      end
      nil
    end

    def transfer_volumes?
      [source_molarity, target_molarity, target_volume, minimum_pick].none?(&:nil?)
    end

    def source_molarity
      molarity_qc_result = labware.receptacle.qc_results.detect { |result| result.key == 'molarity' }
      molarity_qc_result.nil? ? nil : molarity_qc_result.value.to_f
    end

    def target_molarity
      purpose_config.transfer_parameters[:target_molarity_nm]
    end

    def target_volume
      purpose_config.transfer_parameters[:target_volume_ul]
    end

    def minimum_pick
      purpose_config.transfer_parameters[:minimum_pick_ul]
    end

    def transfer_volumes
      volumes = calculate_pick_volumes(
        target_molarity: target_molarity,
        target_volume: target_volume,
        source_molarity: source_molarity,
        minimum_pick: minimum_pick
      )

      yield 'Sample Volume *', "#{volumes[:sample_volume].round} µl"
      yield 'Buffer Volume *', "#{volumes[:buffer_volume].round} µl"
      nil
    end
  end
end
