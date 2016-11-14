# frozen_string_literal: true
# This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2011,2012,2015 Genome Research Ltd.
module Presenters::Statemachine
  module StateDoesNotAllowChildCreation
    def control_child_plate_creation(&block)
      # Does nothing because you can't!
    end

    def control_additional_creation(&block)
      # Does nothing because you can't!
    end

    def suggested_purposes
    end

    def compatible_purposes
    end
  end

  module StateAllowsChildCreation
    # Yields to the block if there are child plates that can be created from the current one.
    # It passes the valid child plate purposes to the block.
    def control_child_plate_creation
      yield unless default_child_purpose.nil?
      nil
    end

    def control_additional_creation
      yield unless default_child_purpose.nil?
      nil
    end

    # Returns the child plate purposes that can be created in the passed state.  Typically
    # this is only one, but it specifically excludes QC plates.
    def default_child_purpose
      labware.plate_purpose.children.detect(&:not_qc?)
    end

    def valid_purposes
      yield default_child_purpose unless default_child_purpose.nil?
      nil
    end

    def suggested_purposes
      labware.plate_purpose.children.each do |purpose|
        yield purpose
      end
    end

    def compatible_purposes
      Settings.purposes.each do |uuid, hash|
        yield uuid, hash['name']
      end
    end
  end

  # These are shared base methods to be used in all presenter state_machines
  module Shared
    #--
    # We ignore the assignment of the state because that is the statemachine getting in before
    # the plate has been loaded.
    #++
    def state=(value) #:nodoc:
      # Ignore this!
    end

    def default_transition
      state_transitions.detect { |t| t.event == :take_default_path }
    end

    # Yields to the block if there is the possibility of controlling the state change, passing
    # the valid next states, along with the current one too.
    def control_state_change
      if default_transition.present?
        # This ugly thing should yield the default transition first followed by
        # any other transitions to states that aren't the default...
        yield(state_transitions.reject { |t| t.to == default_transition.to })
      elsif state_transitions.present?
        # ...if there's no default transition but there are still other transitions
        # present then yield those.
        yield(state_transitions)
      end
    end

    def default_state_change
      yield default_transition unless default_transition.nil?
    end

    # Does nothing
    def control_additional_printing(&block)
    end

    def all_plate_states
      self.class.state_machines[:state].states.map(&:value)
    end

    def state
      labware.try(:state)
    end
  end

  # State transitions are common across all of the statemachines.
  module StateTransitions #:nodoc:
    def self.inject(base)
      base.instance_eval do
        event :take_default_path do
          transition pending: :passed
        end

        event :transfer do
          transition [:pending, :started] => :passed
        end

        event :cancel do
          transition [:pending, :started, :passed] => :cancelled
        end
      end
    end
  end

  def self.included(base)
    base.class_eval do
      include Shared

      # The state machine for plates which has knock-on effects on the plates that can be created
      state_machine :state, initial: :pending do
        StateTransitions.inject(self)

        # These are the states, which are really the only things we need ...
        state :pending do
          include StateAllowsChildCreation
        end

        state :started do
          include StateAllowsChildCreation
        end

        state :passed do
          include StateAllowsChildCreation
        end

        state :qc_complete, human_name: 'QC Complete' do
          include StateAllowsChildCreation
        end

        state :cancelled do
          include StateDoesNotAllowChildCreation
        end
      end
    end
  end
end
