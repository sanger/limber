module Presenters
  module Statemachine
    module Pcr
      def self.included(base)
        base.class_eval do
          include Presenters::Statemachine::Shared

          state_machine :state, :initial => :pending do

            event :take_default_path do
              transition :pending    => :started_fx
              transition :started_fx => :started_mj
              transition :started_mj => :passed
            end

            # event :pass do
            #   transition [ :pending, :started_mj ] => :passed
            # end

            # These are the states, which are really the only things we need ...
            state :pending do
              include Statemachine::StateDoesNotAllowChildCreation
            end

            state :started_fx, :human_name => 'FX robot started' do
              include Statemachine::StateDoesNotAllowChildCreation
            end

            state :started_mj, :human_name => 'MJ robot started' do
              include Statemachine::StateDoesNotAllowChildCreation
            end

            state :passed do
              # Yields to the block if there are child plates that can be created from the current one.
              # It passes the valid child plate purposes to the block.
              def control_additional_creation(&block)
                yield unless default_child_purpose.nil?
                nil
              end

              # Returns the child plate purposes that can be created in the qc_complete state.
              def default_child_purpose
                labware.plate_purpose.children.first
              end
            end

            state :cancelled do
              include Statemachine::StateDoesNotAllowChildCreation
            end

            event :cancel do
              transition [ :pending, :started_fx, :started_mj, :passed ] => :cancelled
            end
          end

        end
      end
    end
  end
end
