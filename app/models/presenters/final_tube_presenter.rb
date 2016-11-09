# frozen_string_literal: true
# This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2012,2013 Genome Research Ltd.
module Presenters
  class FinalTubePresenter
    include Presenter
    include Statemachine::Shared

    class_attribute :labware_class
    self.labware_class = :tube

    self.attributes =  [:api, :labware]

    class_attribute    :additional_creation_partial
    self.additional_creation_partial = nil

    class_attribute :tab_views
    self.tab_views = {
      'labware-summary-button'  => ['labware-summary', 'tube-printing'],
      'labware-creation-button' => ['labware-summary', 'tube-creation'],
      'labware-state-button'    => ['labware-summary', 'tube-state']
    }

    class_attribute    :tab_states

    class_attribute    :authenticated_tab_states
    self.authenticated_tab_states = {
      pending: ['labware-summary-button', 'labware-state-button'],
      started: ['labware-summary-button', 'labware-state-button'],
      passed: ['labware-summary-button', 'labware-state-button'],
      qc_complete: ['labware-summary-button'],
      cancelled: ['labware-summary-button'],
      failed: ['labware-summary-button']
    }

    state_machine :state, initial: :pending do
      event :take_default_path do
        transition pending: :passed
      end

      event :pass do
        transition [:pending, :started] => :passed
      end

      event :cancel do
        transition [:pending, :started] => :cancelled
      end

      state :pending do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :started do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :passed do
        def has_qc_data?
          true
        end
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :qc_complete, human_name: 'QC Complete' do
        def has_qc_data?
          true
        end
        include Statemachine::StateDoesNotAllowChildCreation
      end

      event :qc_complete do
        transition passed: :qc_complete
      end
    end

    def control_child_links
      # Do nothing
    end

    # The state is delegated to the tube
    delegate :state, to: :labware

    # Purpose returns the plate or tube purpose of the labware.
    # Currently this needs to be specialised for tube or plate but in future
    # both should use #purpose and we'll be able to share the same method for
    # all presenters.
    delegate :purpose, to: :labware

    def label_text
      "#{labware.label.prefix} #{labware.label.text || LABEL_TEXT}"
    end

    def label_name
      "#{labware.barcode.prefix} #{labware.barcode.number}"
    end

    def sample_count
      labware.aliquots.count
    end

    def label_suffix
      "P#{sample_count}"
    end

    def labware_form_details(view)
      { url: view.limber_tube_path(labware), as: :tube }
    end

    def qc_owner
      labware
    end

    def label_description
      "#{prioritized_name(labware.name, 10)} #{label_text}"
    end
  end
end
