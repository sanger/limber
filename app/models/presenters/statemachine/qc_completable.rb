#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2013,2015 Genome Research Ltd.
module Presenters
  module Statemachine
    module QcCompletable

      module QcCreatableStep
        def self.included(base)
          base.instance_eval do
            def control_additional_creation(&block)
              yield unless default_child_purpose.nil?
              nil
            end

            def valid_purposes
              yield default_child_purpose unless default_child_purpose.nil?
              nil
            end

            def default_child_purpose
              purpose.children.detect(&:is_qc?)
            end
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
              transition :pending => :passed
              transition :passed  => :qc_complete
            end

            event :pass do
              transition [ :pending, :started ] => :passed
            end

            event :qc_complete do
              transition :passed => :qc_complete
            end

            state :started do
              include StateDoesNotAllowChildCreation
            end

            state :pending do
              include StateDoesNotAllowChildCreation
            end

            state :passed do
              def has_qc_data?; true; end
              include QcCreatableStep
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
                labware.plate_purpose.children.detect(&:not_qc?)
              end

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
