#This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2015 Genome Research Ltd.
module Presenters
  module Statemachine
    module PendingPlateCreation
      def self.included(base)
        base.class_eval do
          include Presenters::Statemachine::Shared

          state_machine :state, :initial => :pending do

            event :take_default_path do
              transition :pending    => :passed
            end

            # These are the states, which are really the only things we need ...
            state :pending do
              include Statemachine::StateAllowsChildCreation
            end

            state :passed do
              include Statemachine::StateDoesNotAllowChildCreation
            end

            state :cancelled do
              include Statemachine::StateDoesNotAllowChildCreation
            end

            event :cancel do
              transition [ :pending, :passed ] => :cancelled
            end
          end

        end
      end
    end
  end
end
