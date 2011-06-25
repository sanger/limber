module Presenters
  class PooledPresenter < PlatePresenter
    include Presenters::Statemachine

    module StateDoesNotAllowTubePreviewing
      def control_tube_preview(&block)
        # Does nothing because you are not allowed to!
      end

      def control_source_view(&block)
        yield
        nil
      end

      def control_tube_view(&block)
        # Does nothing because you are not allowed to!
      end
    end

    state_machine :tube_state, :initial => :pending, :namespace => 'tube' do
      Presenters::Statemachine::StateTransitions.inject(self)

      state :pending do
        include StateDoesNotAllowTubePreviewing
      end
      state :started do
        include StateDoesNotAllowTubePreviewing
      end
      state :passed do
        def control_tube_preview(&block)
          yield unless plate.has_transfers_to_tubes?
          nil
        end

        def control_source_view(&block)
          yield unless plate.has_transfers_to_tubes?
          nil
        end

        def control_tube_view(&block)
          yield if plate.has_transfers_to_tubes?
          nil
        end
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

    write_inheritable_attribute :page, 'pooled_plate'

  end
end
