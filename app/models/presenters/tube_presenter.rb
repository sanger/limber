# frozen_string_literal: true
# This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2011,2012,2013 Genome Research Ltd.
module Presenters
  class TubePresenter
    def qc_owner
      labware
    end

    include Presenter
    include Statemachine::Shared

    class_attribute :labware_class
    self.labware_class = :tube

    self.attributes =  [:api, :labware]

    class_attribute :additional_creation_partial
    self.additional_creation_partial = 'labware/tube/child_tube_creation'

    class_attribute :tab_states

    LABEL_TEXT = 'ILB Stock'

    def label_text
      "#{labware.label.prefix} #{labware.label.text || LABEL_TEXT}"
    end

    def label_name
      "#{labware.barcode.prefix} #{labware.barcode.number}"
    end

    def control_child_links(&block)
      # Mostly, no.
    end

    def default_statechange_label
      'Move tube to next state'
    end

    # The state is delegated to the tube
    delegate :state, to: :labware

    def label_description
      "#{prioritized_name(labware.name, 10)} #{label_text}"
    end

    def sample_count
      labware.aliquots.count
    end

    def label_suffix
      "P#{sample_count}"
    end

    # Purpose returns the plate or tube purpose of the labware.
    # Currently this needs to be specialised for tube or plate but in future
    # both should use #purpose and we'll be able to share the same method for
    # all presenters.
    delegate :purpose, to: :labware

    def labware_form_details(view)
      { url: view.limber_tube_path(labware), as: :tube }
    end

    class UnknownTubeType < StandardError
      attr_reader :tube

      def initialize(tube)
        super("Unknown plate type #{tube.purpose.name.inspect}")
        @tube = tube
      end
    end

    def self.lookup_for(labware)
      (presentation_classes = Settings.purposes[labware.purpose.uuid]) || raise(UnknownTubeType, labware)
      presentation_classes[:presenter_class].constantize
    end
  end
end
