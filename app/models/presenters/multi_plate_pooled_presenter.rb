class Presenters::MultiPlatePooledPresenter < Presenters::PooledPresenter
  write_inheritable_attribute :summary_partial, 'labware/plates/multi_pooled_plate'
  write_inheritable_attribute :printing_partial, 'labware/plates/tube_printing'

  write_inheritable_attribute :csv, 'show_pooled'



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
      def has_qc_data?; true; end
      include Presenters::Statemachine::StateAllowsChildCreation
      transition [ :nx_in_progress ] => :passed
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

  write_inheritable_attribute :robot_controlled_states, { :pending => 'nx8-pre-cap-pool' }

  def bed_prefix
    'PCRXP'
  end

  def transfers
    self.labware.creation_transfers.map do |ct|
      source_ean = ct.source.barcode.ean13
      source_barcode = "#{ct.source.barcode.prefix}#{ct.source.barcode.number}"
      source_stock = "#{ct.source.stock_plate.barcode.prefix}#{ct.source.stock_plate.barcode.number}"
      destination_ean = ct.destination.barcode.ean13
      destination_barcode = "#{ct.destination.barcode.prefix}#{ct.destination.barcode.number}"
      transfers = ct.transfers.reverse_merge(all_wells).sort {|a,b| split_location(a.first) <=> split_location(b.first) }
      {
        :source_ean          => source_ean,
        :source_barcode      => source_barcode,
        :source_stock        => source_stock,
        :destination_ean     => destination_ean,
        :destination_barcode => destination_barcode,
        :transfers           => transfers
      }
    end
  end

  def all_wells
    return @all_wells unless @all_wells.nil?
    @all_wells = {}
    ('A'..'H').each {|r| (1..12).each{|c| @all_wells["#{r}#{c}"]="H12"}}
    @all_wells
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

end
