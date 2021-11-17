# frozen_string_literal: true

# Helper methods for calculating volumes and concentrations in sample transfers.
module TransfersHelper
  # Calculates the source volume and the buffer volume to reach a target molarity
  # and volume given a source molarity.
  #
  # @param target_molarity [Float] The target molarity in the same units as +source_molarity+.
  # @param target_volume [Float] The intended volume after the transfer is complete.
  # @param source_molarity [Float] The source molarity of the sample being transfered.
  #        The units should match those in the +target_molarity+.
  # @param minimum_pick [Float] The minimum pick volume possible for both the sample and the buffer.
  #        Units should match the +target_volume+.
  #
  # @return [Hash] A hash containing keys +:sample_volume+ and +:buffer_volume+ for the transfer.
  #         Volumes in the return hash use the same units as the +target_volume+ parameter.
  def calculate_pick_volumes(target_molarity:, target_volume:, source_molarity:, minimum_pick:)
    sample_volume = (target_molarity.to_f / source_molarity) * target_volume
    sample_volume = [sample_volume, minimum_pick].max
    buffer_volume = target_volume - sample_volume

    if buffer_volume < minimum_pick
      { sample_volume: target_volume, buffer_volume: 0 }
    else
      { sample_volume: sample_volume, buffer_volume: buffer_volume }
    end
  end
end
