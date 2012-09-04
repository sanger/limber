class StateChangers::PlateToTubeStateChanger < StateChangers::QcCompletablePlateStateChanger
  def move_to!(state, reason)
    super
    create_stock_tubes! if state == 'qc_complete'
  end

  def create_stock_tubes!
    child_stock_tubes = api.tube_creation.create!(
      :user          => user_uuid,
      :parent        => labware_uuid,
      :child_purpose => Settings.purpose_uuids.fetch('ILB_STD_STOCK')
    ).children

    plate_to_tube_template.create!(
      :user         => user_uuid,
      :source       => labware_uuid,
      :targets => child_stock_tubes.map(&:uuid)
    )
  end
  private :create_stock_tubes!

  def plate_to_tube_template
    api.transfer_template.find(
      Settings.transfer_templates['Transfer wells to specific tubes by submission']
    )
  end
  private :plate_to_tube_template

end
