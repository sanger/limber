class Presenters::MultiPlatePooledPresenter < Presenters::PooledPresenter
  write_inheritable_attribute :summary_partial, 'lab_ware/plates/multi_pooled_plate'
  write_inheritable_attribute :printing_partial, 'lab_ware/plates/tube_printing'

  write_inheritable_attribute :csv, 'show_pooled'

  state_machine :state, :initial => :pending do
    Presenters::Statemachine::StateTransitions.inject(self)

    state :pending do
      include StateDoesNotAllowChildCreation
    end
    state :started do
      include StateDoesNotAllowChildCreation
    end

    state :nx_in_progress do
      include StateDoesNotAllowChildCreation
    end

    event :pass do
      transition [ :nx_in_progress ] => :passed
    end

    state :failed do

    end
    state :cancelled do

    end
  end

  write_inheritable_attribute :authenticated_tab_states, {
    :pending        =>  [ 'summary-button', 'robot-verification-button' ],
    :started        =>  [ 'summary-button', 'robot-verification-button' ],
    :nx_in_progress =>  [ 'summary-button', 'plate-state-button' ],
    :passed         =>  [ 'plate-creation-button','summary-button', 'well-failing-button', 'plate-state-button' ],
    :cancelled      =>  [ 'summary-button' ],
    :failed         =>  [ 'summary-button' ]
  }

  write_inheritable_attribute :robot_name, 'nx8-pre-cap-pool'
  write_inheritable_attribute :bed_prefix, 'PCRXP'

  def transfers
    self.plate.creation_transfers.map do |ct|
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
    (self.plate.creation_transfers.count/4.0).ceil.times do |i|
      links << [i+1,"#{Rails.application.routes.url_helpers.pulldown_plate_path(plate.uuid)}.csv?offset=#{i}"]
    end
    links
  end

  def filename(offset=nil)
    return true if offset.nil?
    "#{plate.stock_plate.barcode.prefix}#{plate.stock_plate.barcode.number}_#{offset.to_i+1}.csv"
  end

end
