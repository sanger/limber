# frozen_string_literal: true
# This file is part of Illumina-B Pipeline is distributed under the terms of GNU General Public License version 3 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2013,2015 Genome Research Ltd.
module Presenters
  class PendingCreationTubePresenter < TubePresenter
    state_machine :state, initial: :pending do
      event :start do
        transition pending: :started
      end

      event :take_default_path do
        transition pending: :passed
      end

      event :pass do
        transition [:pending, :started] => :passed
      end

      event :fail do
        transition [:passed] => :failed
      end

      event :cancel do
        transition [:pending, :started] => :cancelled
      end

      state :pending do
        include Statemachine::StateAllowsChildCreation
        def default_child_purpose
          purpose.children.first
        end
      end

      state :started do
        include Statemachine::StateDoesNotAllowChildCreation
      end

      state :passed do
        include Statemachine::StateAllowsChildCreation
        def default_child_purpose
          purpose.children.last
        end
      end
    end
  end
end
