module Presenters
  module Statemachine
    module QcCompletable

      module QcCreatableStep
        def control_additional_creation(&block)
          yield unless default_child_purpose.nil?
          nil
        end

        def default_child_purpose
          labware.plate_purpose.children.detect {|purpose| Settings.qc_purposes.include?(purpose.name) }
        end
      end

      def self.included(base)
        base.class_eval do
          include Presenters::Statemachine::Shared

          state_machine :state, :initial => :pending do
            event :start do
              transition :pending => :started
            end

            event :take_default_path do
              transition :pending => :started
              transition :started => :passed
              transition :passed  => :qc_complete
            end

            event :pass do
              transition [ :pending, :started ] => :passed
            end

            event :qc_complete do
              transition :passed => :qc_complete
            end

            state :pending do
              include QcCreatableStep
            end

            state :passed do
              def has_qc_data?; true; end
              include StateDoesNotAllowChildCreation
            end

            state :qc_complete, :human_name => 'QC Complete' do
              # Yields to the block if there are child plates that can be created from the current one.
              # It passes the valid child plate purposes to the block.
              def control_additional_creation(&block)
                yield unless default_child_purpose.nil?
                nil
              end

              # Returns the child plate purposes that can be created in the qc_complete state.
              def default_child_purpose
                labware.plate_purpose.children.detect do |purpose|
                  not_qc?(purpose) && suitable_child?(purpose)
                end
              end

              def not_qc?(purpose)
                !Settings.qc_purposes.include?(purpose.name)
              end
              private :not_qc?

              def suitable_child?(purpose)
                Settings.purposes[labware.plate_purpose.uuid].locations_children.nil? ||
                Settings.purposes[labware.plate_purpose.uuid].locations_children[location] == purpose.name
              end
              private :suitable_child?

              def has_qc_data?; true; end
            end

            event :fail do
              transition [ :passed ] => :failed
            end

            event :cancel do
              transition [ :pending, :started, :passed, :qc_complete ] => :cancelled
            end
          end
        end
      end
    end
  end
end
