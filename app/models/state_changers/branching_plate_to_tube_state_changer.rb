# frozen_string_literal: true

class StateChangers::BranchingPlateToTubeStateChanger < StateChangers::QcCompletablePlateStateChanger
  EVENT_TYPE = 'lib_pcr_xp_created'

  def move_to!(state, reason, customer_accepts_responsibility = false)
    generate_event! if state == 'passed'
    raise StateChangers::StateChangeError, 'QC plate must be created first!' if state == 'qc_complete' && !qc_created?
    super
    create_stock_tubes! if state == 'qc_complete' && tubes_required?
  end

  def qc_created?
    labware.source_transfers.size >= 1
  end

  def create_stock_tubes!
    child_stock_tubes = api.specific_tube_creation.create!(
      user: user_uuid,
      parent: labware_uuid,
      child_purposes: pool_purposes.values
    ).children

    plate_to_tube_template.create!(
      user: user_uuid,
      source: labware_uuid,
      targets: pool_targets(child_stock_tubes)
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
    @pool_purposes ||= labware.pools.each_with_object({}) do |pool, pool_purposes|
      pool_purposes[pool.first] = purpose_for(pool.last)
    end
  end
  private :pool_purposes

  def purpose_for(pool)
    Settings.purpose_uuids[
      Settings.purposes[pool['target_tube_purpose']].from_purpose
    ]
  end
  private :purpose_for

  def tubes_required?
    Settings.purposes[labware.pools.values.first['target_tube_purpose']].try(:from_purpose).present?
  end

  def pool_targets(child_tubes)
    targets = child_tubes.to_a
    pool_purposes.each_with_object({}) do |pool_pool_purpose, pool_targets|
      pool_targets[pool_pool_purpose.first] = allocate_tube!(targets, pool_pool_purpose.last)
    end
  end
  private :pool_targets

  def allocate_tube!(targets, purpose_uuid)
    tube = targets.detect { |tube| tube.purpose.uuid == purpose_uuid }
    targets.delete(tube)
  end
  private :allocate_tube!

  def generate_event!
    api.library_event.create!(
      seed: labware_uuid,
      user: user_uuid,
      event_type: EVENT_TYPE
    )
  end
  private :generate_event!
end
