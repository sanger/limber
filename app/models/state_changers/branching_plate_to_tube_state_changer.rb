class StateChangers::BranchingPlateToTubeStateChanger < StateChangers::QcCompletablePlateStateChanger

  def move_to!(state, reason)
    raise StateChangers::StateChangeError, "QC plate must be created first!" if state == 'qc_complete' && !qc_created?
    super
    create_stock_tubes! if state == 'qc_complete' && tubes_required?
  end

  def qc_created?
    labware.source_transfers.size >= 1
  end

  def create_stock_tubes!
    child_stock_tubes = api.specific_tube_creation.create!(
      :user           => user_uuid,
      :parent         => labware_uuid,
      :child_purposes => pool_purposes.values
    ).children

    plate_to_tube_template.create!(
      :user           => user_uuid,
      :source         => labware_uuid,
      :targets        => pool_targets(child_stock_tubes)
    )
  end
  private :create_stock_tubes!

  def plate_to_tube_template
    api.transfer_template.find(
      Settings.transfer_templates['Transfer wells to specific tubes defined by submission']
    )
  end
  private :plate_to_tube_template

  def pool_purposes
    @pool_purposes ||= labware.pools.inject(Hash.new) do |pool_purposes, pool|
      pool_purposes[pool.first] = purpose_for(pool.last)
      pool_purposes
    end
  end
  private :pool_purposes

  def purpose_for(pool)
    Settings.purpose_uuids[
      Settings.purposes[pool["target_tube_purpose"]].from_purpose
    ]
  end
  private :purpose_for

  def tubes_required?
    Settings.purposes[labware.pools.values.first["target_tube_purpose"]].try(:from_purpose).present?
  end

  def pool_targets(child_tubes)
    targets = child_tubes.to_a
    pool_purposes.inject(Hash.new) do |pool_targets, pool_pool_purpose|
      pool_targets[pool_pool_purpose.first] = allocate_tube!(targets,pool_pool_purpose.last)
      pool_targets
    end
  end
  private :pool_targets

  def allocate_tube!(targets,purpose_uuid)
    tube = targets.detect {|tube| tube.purpose.uuid == purpose_uuid}
    targets.delete(tube)
  end
  private :allocate_tube!

end
