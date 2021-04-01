# frozen_string_literal: true

# Can be included in plate creators which require well aliquots to have concentrations
module LabwareCreators::TaggedPlateBehaviour
  extend ActiveSupport::Concern

  included do
    # If I call `tag_plates_used?`, it calls `tag_plates.used?`
    # where `tag_plates` is a method in this class, returning an instance of TagCollection
    # similar for `list` and `names`
    delegate :used?, :list, :names, to: :tag_plates, prefix: true
  end
  #
  # Update the state of the tag plate to 'exhausted'
  #
  # @return [Sequencescape::Api::StateChange] The created state change
  #
  def flag_tag_plate_as_exhausted
    api.state_change.create!(
      user: user_uuid,
      target: tag_plate.asset_uuid,
      reason: 'Used in Library creation',
      target_state: 'exhausted'
    )
  end

  def transfer_hash
    WellHelpers.stamp_hash(parent.size)
  end

  def tag_plates
    @tag_plates ||= LabwareCreators::Tagging::TagCollection.new(api, labware, purpose_uuid)
  end

  #
  # Indicated that an i5 tag (tag2) is required for the tagging of this
  # particular plate. i5 tags are required when a submission spans multiple
  # plates, which will be tagged independently, and then pooled.
  #
  # The combination of i5 and i7 tags help ensure that each sample in the pool
  # has a unique tag. By using a combination of two tags you can maintain
  # strong diversity in tag reads.
  #
  # @return [Boolean] Returns true if any submissions associated with the plate
  #                   span multiple source plates.
  #
  def requires_tag2?
    cross_plate_pool_detection? &&
      parent.submission_pools.any? { |pool| pool.plates_in_submission > 1 }
  end

  #
  # In the LTHR pipeline we begin with 4x96 well plates, which get combined
  # on a single 384 well plate. This means that the cross-plate pool detection
  # enforces unique UDI plates. This causes problems if a tag plate is used in
  # error, and there needs to be a rework loop. As on the second run through,
  # tag clash detection fires.
  #
  # By setting the disable_cross_plate_pool_detection config option you can
  # turn off this check.
  #
  # @note This option is safest to enable when:
  #       - The pipeline has an earlier consolidation step
  #       - The pipeline will never pool at a higher level than the current late
  #       - Only one template is available anyway
  #       In other scenarios you may be at risk of introducing tag clashes.
  #
  # @return [Bool] Whether to disable tag uniqueness detection
  #
  def cross_plate_pool_detection?
    !purpose_config.fetch(:disable_cross_plate_pool_detection, false)
  end
end
