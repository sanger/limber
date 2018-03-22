# frozen_string_literal: true

module Presenters
  class TubePresenter
    include Presenter
    include Statemachine::Shared
    include RobotControlled

    self.labware_class = :tube
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
    delegate :purpose, :state, to: :labware

    def label
      Labels::TubeLabel.new(labware)
    end

    def control_child_links(&block)
      # Mostly, no.
    end

    def sample_count
      labware.aliquots.count
    end

    def labware_form_details(view)
      { url: view.limber_tube_path(labware), as: :tube }
    end

    def tag_sequences
      @tag_sequences ||= labware.aliquots.each_with_object([]) do |aliquot, tags|
        tags << [aliquot.tag.try(:oligo), aliquot.tag2.try(:oligo)]
      end
    end

    def sequencescape_submission
      return nil if purpose_config.submission.empty?
      s = SequencescapeSubmission.new(purpose_config.submission.to_hash.merge(assets: [labware.uuid]))
      yield s if block_given?
      s
    end
  end
end
