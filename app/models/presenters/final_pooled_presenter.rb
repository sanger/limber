# frozen_string_literal: true
# This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2011,2012,2014,2015 Genome Research Ltd.
class Presenters::FinalPooledPresenter < Presenters::PooledPresenter
  include Presenters::Statemachine
  include Presenters::AlternativePooling

  self.summary_partial = 'labware/plates/pooled_into_tubes_plate'
  self.printing_partial = 'labware/plates/tube_printing'
  self.csv = 'show_pooled_alternative'

  self.authenticated_tab_states = {
    pending: ['labware-summary-button', 'labware-state-button'],
    started: ['labware-state-button',   'labware-summary-button'],
    passed: ['labware-summary-button', 'labware-state-button'],
    cancelled: ['labware-summary-button'],
    failed: ['labware-summary-button']
  }

  def tube_label_text
    labware.tubes.map do |tube|
      "#{tube.label.prefix} #{tube.label.text}"
    end
  end

  def default_tube_printer_uuid
    Settings.printers[:tube]
  end

  module StateDoesNotAllowTubePreviewing
    def control_tube_preview(&block)
      # Does nothing because you are not allowed to!
    end

    def control_source_view
      yield
      nil
    end

    def control_tube_view(&block)
      # Does nothing because you have no tubes
    end
    alias control_additional_printing control_tube_view
  end

  module PreviewTubeTransfers
    def control_source_view
      yield unless plate.has_transfers_to_tubes?
      nil
    end

    def control_tube_view
      yield if plate.has_transfers_to_tubes?
      nil
    end
    alias control_additional_printing control_tube_view

    def transfers
      labware.well_to_tube_transfers
    end
  end

  state_machine :tube_state, initial: :pending, namespace: 'tube' do
    Presenters::Statemachine::StateTransitions.inject(self)

    state :pending do
      include PreviewTubeTransfers
    end
    state :started do
      include PreviewTubeTransfers
    end
    state :passed do
      include PreviewTubeTransfers
    end
    state :failed do
      include StateDoesNotAllowTubePreviewing
    end
    state :cancelled do
      include StateDoesNotAllowTubePreviewing
    end
  end

  def tube_state
    plate.state
  end

  def tube_state=(state)
    # Ignore this
  end
end
