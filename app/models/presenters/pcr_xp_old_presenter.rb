class Presenters::PcrXpOldPresenter < Presenters::PcrXpPresenter

  write_inheritable_attribute :authenticated_tab_states, {
    :pending     => [ 'labware-summary-button', 'labware-state-button' ],
    :started     => [ 'labware-state-button', 'labware-summary-button' ],
    :passed      => [ 'labware-state-button', 'labware-summary-button', 'well-failing-button', 'labware-creation-button' ],
    :qc_complete => [ 'labware-summary-button', 'labware-state-button' ],
    :cancelled   => [ 'labware-summary-button' ],
    :failed      => [ 'labware-summary-button' ]
  }

end
