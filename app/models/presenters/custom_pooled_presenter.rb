class Presenters::CustomPooledPresenter < Presenters::PooledPresenter
  write_inheritable_attribute :summary_partial, 'labware/plates/custom_pooled_plate'
  write_inheritable_attribute :printing_partial, 'labware/plates/tube_printing'

  state_machine :pooled_state, :initial => :pending, :namespace => 'pooled' do
    Presenters::Statemachine::StateTransitions.inject(self)

    state :pending do

    end
    state :started do

    end
    state :passed do
      def control_source_view(&block)
        yield
        nil
      end
    end
    state :failed do

    end
    state :cancelled do

    end
  end

  def pooled_state
    plate.state
  end

  def pooled_state=(state)
    # Ignore this
  end
end
