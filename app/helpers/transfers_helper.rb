# frozen_string_literal: true

# Helper methods for calculating volumes and concentrations in sample transfers.
module TransfersHelper
  # Calculates the pick volume and the buffer volume to reach a target molarity
  # and volume given a source molarity.
  #
  # Params:
  #  - target_molarity:  The target molarity in the same units as source_molarity.
  #  - target_volume:    The intended volume after the transfer is complete.
  #  - source_molarity:  The source molarity of the sample being transfered.
  #                      The units should match those in the target_molarity.
  #  - minimum_pick:     The minimum pick possible for both the sample and the buffer.
  #                      Units should match the target_volume.
  #
  # Returns:
  #  - A hash containing keys :pick_volume and :buffer_volume for the transfer.
  #    Volumes in the return hash use the same units as the target_volume parameter.
  def calculate_pick_volumes(target_molarity, target_volume, source_molarity, minimum_pick)
    pick_volume = (target_molarity / source_molarity) * target_volume
    pick_volume = [pick_volume, minimum_pick].max
    buffer_volume = target_volume - pick_volume

    if buffer_volume < minimum_pick
      { pick_volume: target_volume, buffer_volume: 0 }
    else
      { pick_volume: pick_volume, buffer_volume: buffer_volume }
    end
  end
end
