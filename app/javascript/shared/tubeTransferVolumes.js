const purposeTargetMolarityParameter = (purposeConfig) =>
  purposeConfig?.transfer_parameters?.target_molarity_nm

const purposeTargetVolumeParameter = (purposeConfig) =>
  purposeConfig?.transfer_parameters?.target_volume_ul

const purposeMinimumPickParameter = (purposeConfig) =>
  purposeConfig?.transfer_parameters?.minimum_pick_ul

const tubeMostRecentMolarity = function(tube) {
  // Get the QC results, find those for molarity entries in nM, inverse sort by the created_at timestamp
  // then take the first item.
  return tube?.receptacle?.qc_results
    ?.filter(result => result.key === 'molarity' && result.units === 'nM')
    .sort((resultA, resultB) => -1 * ('' + resultA.created_at).localeCompare(resultB.created_at))[0]
    ?.value
}

// Calculates the source volume and the buffer volume to reach a target molarity
// and volume given a source molarity.
//
// target_molarity [Float] The target molarity in the same units as source_molarity.
// target_volume [Float] The intended volume after the transfer is complete.
// source_molarity [Float] The source molarity of the sample being transfered.
//        The units should match those in the target_molarity.
// minimum_pick [Float] The minimum pick volume possible for both the sample and the buffer.
//        Units should match the target_volume.
//
// [Object] An Object containing keys sampleVolume and bufferVolume for the transfer.
//          Volumes in the return Object use the same units as the target_volume parameter.
const calculateTransferVolumes = function(target_molarity, target_volume, source_molarity, minimum_pick) {
  const calc_sample_volume = (target_molarity / source_molarity) * target_volume
  const sample_volume = Math.max(calc_sample_volume, minimum_pick)
  const buffer_volume = target_volume - sample_volume

  if (buffer_volume < minimum_pick) {
    return { sampleVolume: target_volume, bufferVolume: 0 }
  } else {
    return { sampleVolume: sample_volume, bufferVolume: buffer_volume }
  }
}

export {
  purposeTargetMolarityParameter,
  purposeTargetVolumeParameter,
  purposeMinimumPickParameter,
  tubeMostRecentMolarity,
  calculateTransferVolumes
}
