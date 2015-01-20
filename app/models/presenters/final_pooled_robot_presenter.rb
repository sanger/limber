class Presenters::FinalPooledRobotPresenter < Presenters::FinalPooledPresenter
  include Presenters::Statemachine
  write_inheritable_attribute :authenticated_tab_states, {
    :pending    =>  [ 'labware-summary-button', 'labware-state-button' ],
    :started    =>  [ 'labware-state-button', 'labware-summary-button' ],
    :passed     =>  [ 'labware-creation-button', 'labware-summary-button', 'labware-state-button'],
    :cancelled  =>  [ 'labware-summary-button' ],
    :failed     =>  [ 'labware-summary-button' ]
  }

  def has_qc_data?; true; end

  write_inheritable_attribute :robot_controlled_states, { :pending => 'nx8-post-cap-lib-pool' }
  write_inheritable_attribute :csv, 'show_pooled_alternative'

  def tube_label_text
    labware.tubes.map do |tube|
      "#{tube.label.prefix} #{tube.label.text}"
    end
  end

  def default_tube_printer_uuid
    Settings.printers[location][:tube]
  end

end
