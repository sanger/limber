class Presenters::MultiPlatePooledPresenter < Presenters::PooledPresenter
  write_inheritable_attribute :summary_partial, 'labware/plates/multi_pooled_plate'
  write_inheritable_attribute :printing_partial, 'labware/plates/tube_printing'

  include ExtendedCsv

  alias_method :transfers, :transfers_for_csv

  include Presenters::Statemachine
  state_machine :state, :initial => :pending do
    Presenters::Statemachine::StateTransitions.inject(self)
    state :pending do
      include Presenters::Statemachine::StateDoesNotAllowChildCreation
    end
    state :started do
      include Presenters::Statemachine::StateDoesNotAllowChildCreation
    end

    state :nx_in_progress do
      include Presenters::Statemachine::StateDoesNotAllowChildCreation
    end

    event :pass do
      transition [ :nx_in_progress ] => :passed
    end

    state :passed do
      include Presenters::Statemachine::StateAllowsChildCreation
      def has_qc_data?; true; end
    end

    state :failed do
      def has_qc_data?; true; end
    end
    state :cancelled do
      def has_qc_data?; true; end
    end
  end

  def authenticated_tab_states
   {
    :pending        =>  [ 'labware-summary-button', 'labware-state-button' ],
    :started        =>  [ 'labware-summary-button', 'labware-state-button' ],
    :nx_in_progress =>  [ 'labware-summary-button', 'labware-state-button' ],
    :passed         =>  [ 'labware-creation-button','labware-summary-button', 'labware-well-failing-button', 'labware-state-button' ],
    :cancelled      =>  [ 'labware-summary-button' ],
    :failed         =>  [ 'labware-summary-button' ]
    }
  end

  def csv_file_links
    links = []
    (self.labware.creation_transfers.count/4.0).ceil.times do |i|
      links << [i+1,"#{Rails.application.routes.url_helpers.illumina_b_plate_path(plate.uuid)}.csv?offset=#{i}"]
    end
    links
  end

  def filename(offset=nil)
    return true if offset.nil?
    "#{plate.stock_plate.barcode.prefix}#{plate.stock_plate.barcode.number}_#{offset.to_i+1}.csv"
  end

  def target_plate_transfers
    Hash[labware.creation_transfers.map {|tf| tf.transfers.values }.flatten.uniq.map {|v| [v,v] }]
  end

end
