#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2013 Genome Research Ltd.
module Presenters

  class TubePresenter

    def qc_owner
      labware
    end

    include Presenter
    include Statemachine::Shared

    class_inheritable_reader :labware_class
    write_inheritable_attribute :labware_class, :tube

    write_inheritable_attribute :attributes, [ :api, :labware ]

    class_inheritable_reader    :additional_creation_partial
    write_inheritable_attribute :additional_creation_partial, 'labware/tube/child_tube_creation'

    class_inheritable_reader    :tab_views
    write_inheritable_attribute :tab_views, {
      'labware-summary-button'          => [ 'labware-summary', 'tube-printing' ],
      'labware-creation-button' => [ 'labware-summary', 'tube-creation' ],
      'labware-QC-button'       => [ 'labware-summary', 'tube-creation' ],
      'labware-state-button'    => [ 'labware-summary', 'tube-state' ]
    }

    class_inheritable_reader    :tab_states

    LABEL_TEXT = 'ILB Stock'

    def label_text
      "#{labware.label.prefix} #{labware.label.text|| LABEL_TEXT}"
    end

    def label_name
      "#{labware.barcode.prefix} #{labware.barcode.number}"
    end

    def control_child_links(&block)
      # Mostly, no.
    end

    # The state is delegated to the tube
    delegate :state, :to => :labware

    def label_description
      "#{prioritized_name(labware.name, 10)} #{label_text}"
    end

    def location
      # TODO: Consider adding location to tube api as well
      :illumina_b
    end

    # Purpose returns the plate or tube purpose of the labware.
    # Currently this needs to be specialised for tube or plate but in future
    # both should use #purpose and we'll be able to share the same method for
    # all presenters.
    def purpose
      labware.purpose
    end

    def labware_form_details(view)
      { :url => view.illumina_b_tube_path(self.labware), :as => :tube }
    end

    class UnknownTubeType < StandardError
      attr_reader :tube

      def initialize(tube)
        super("Unknown plate type #{tube.purpose.name.inspect}")
        @tube = tube
      end
    end

    def self.lookup_for(labware)
      presentation_classes = Settings.purposes[labware.purpose.uuid] or raise UnknownTubeType, labware
      presentation_classes[:presenter_class].constantize
    end
  end
end
