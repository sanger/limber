const purposeTargetMolarityParameter = (purposeConfig) =>
  purposeConfig?.transfer_parameters?.target_molarity_nm

const purposeTargetVolumeParameter = (purposeConfig) =>
  purposeConfig?.transfer_parameters?.target_volume_ul

const purposeMinimumPickParameter = (purposeConfig) =>
  purposeConfig?.transfer_parameters?.minimum_pick_ul

const tubeMostRecentMolarity = function(tube) {
  // Get the QC results,
  // find those for molarity entries in nM,
  // inverse sort by the created_at timestamp,
  // inverse sort by the id,
  // take the first item and parse the value to a float.
  const qcResults = tube?.receptacle?.qc_results
  const molarityEntries =  qcResults?.filter(result => result.key === 'molarity' && result.units === 'nM')
  const sortedByCreatedAt = molarityEntries?.sort((resultA, resultB) => -1 * ('' + resultA.created_at).localeCompare(resultB.created_at))
  const sortedByIds = sortedByCreatedAt?.sort((resultA, resultB) => parseInt(resultA.id) > parseInt(resultB.id) ? -1 : 1)
  const mostRecentMolarityResult = sortedByIds?.[0]
  return mostRecentMolarityResult ? parseFloat(mostRecentMolarityResult?.value) : undefined
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
// [Object] An Object containing keys sampleVolume, bufferVolume and belowTarget for the transfer.
//          Volumes in the return Object use the same units as the target_volume parameter.
//          The boolean returned in belowTarget indicates whether the target_molarity was achieved or
//          if the actual molarity is below the target due to a weak concentration of source sample.
const calculateTransferVolumes = function(target_molarity, target_volume, source_molarity, minimum_pick) {
  const calc_sample_volume = (target_molarity / source_molarity) * target_volume
  const sample_volume = Math.max(calc_sample_volume, minimum_pick)
  const buffer_volume = target_volume - sample_volume

  if (buffer_volume < minimum_pick) {
    return { sampleVolume: target_volume, bufferVolume: 0, belowTarget: buffer_volume < 0 }
  } else {
    return { sampleVolume: sample_volume, bufferVolume: buffer_volume, belowTarget: false }
  }
}

export {
  purposeTargetMolarityParameter,
  purposeTargetVolumeParameter,
  purposeMinimumPickParameter,
  tubeMostRecentMolarity,
  calculateTransferVolumes
}
