# frozen_string_literal: true

module Presenters
  # Used in the Ultima conversion pipelines for the plate on which normalisation,
  # Ultima tagging and PCR are done (e.g. ULTP DNA Norm). As they are done on the
  # same physical plate, each step is a state of this plate:
  #
  #   pending     -> Manual Transfer -> processed_1 (normalised)
  #   processed_1 -> Add Ultima Tags -> processed_2 (tags, PCR mix and primer added)
  #   processed_2 -> Perform PCR     -> passed
  #
  # The tags are added on the custom tagged plate page for this plate (see
  # Plates::TagLayoutsController), which then moves the plate to processed_2.
  # Child creation is only allowed when passed, i.e. once the PCR is done.
  # Sequencescape allows these transitions, and failing or cancelling the plate
  # at each step. The plate does not use the 'started' and 'processed' states
  # because Sequencescape does not allow failing or cancelling from 'processed'.
  class UltimaConversionPresenter < PlatePresenter
    include Statemachine::Shared

    self.state_transition_name_scope = :ultima_conversion

    TAGGING_STATE = 'processed_1'
    TAGGED_STATE = 'processed_2'
    TAGGING_LABEL = 'Add Ultima Tags'

    # Reminders shown on the plate page, as the state names do not describe the steps
    STATE_MESSAGES = {
      'pending' => 'Click Manual Transfer when the normalisation is done.',
      'processed_1' => 'Normalised. Make the conversion submission, then add the Ultima tags.',
      'processed_2' => 'Ultima tags added. Run the PCR, then click Perform PCR.'
    }.freeze

    # There is no 'transfer' event as in the other presenters, which would allow
    # skipping the steps by changing the state to passed.
    state_machine :state, initial: :pending do
      # processed_1 -> processed_2 is done by adding the tags, not with a state change button
      event :take_default_path, human_name: 'Manual Transfer' do
        transition pending: :processed_1
        transition processed_2: :passed
      end

      event :cancel do
        transition %i[pending processed_1 processed_2 passed] => :cancelled
      end

      # We use `fail_labware` here as `fail` is defined on Object (its an alias for `raise`)
      event :fail_labware, human_name: 'Fail' do
        transition %i[pending processed_1 processed_2 passed] => :failed
      end

      state :pending do
        include Statemachine::StateDoesNotAllowChildCreation
        include Statemachine::DoesNotAllowLibraryPassing
      end

      state :processed_1 do
        include Statemachine::StateDoesNotAllowChildCreation
        include Statemachine::DoesNotAllowLibraryPassing
      end

      state :processed_2 do
        include Statemachine::StateDoesNotAllowChildCreation
        include Statemachine::DoesNotAllowLibraryPassing
      end

      state :passed do
        include Statemachine::StateAllowsChildCreation
        include Statemachine::DoesNotAllowLibraryPassing
      end

      state :cancelled do
        include Statemachine::StateDoesNotAllowChildCreation
        include Statemachine::DoesNotAllowLibraryPassing
      end

      state :failed do
        include Statemachine::StateDoesNotAllowChildCreation
        include Statemachine::DoesNotAllowLibraryPassing
      end
    end

    validates_with Validators::SuboptimalValidator
    validates_with Validators::ActiveRequestValidator

    def initialize(*args)
      super
      message = STATE_MESSAGES[state]
      @info_messages << message if message
    end

    # Shows the tagging link in the sidebar. Tags can be added once there is a
    # submission for the next step (the conversion submission), which offers the
    # next child purpose.
    def tagging_allowed?
      state == TAGGING_STATE && suggested_purposes.present?
    end

    def tagged_state
      TAGGED_STATE
    end

    def tagging_label
      TAGGING_LABEL
    end
  end
end
