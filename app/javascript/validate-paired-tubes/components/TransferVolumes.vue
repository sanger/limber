<template>
  <b-card header="Transfer Volumes" header-tag="h3">
    <p v-show="!readyToDisplayResult">Once paired tubes are scanned in, transfer volumes will be shown here.</p>
    <div v-show="readyToDisplayResult">
      <p>
        The transfer volumes shown are to make a {{ targetVolumeForDisplay }} μl / {{ targetMolarityForDisplay }} nM
        solution.
      </p>
      <dl class="row metadata">
        <dt>Sample Volume</dt>
        <dd>{{ sampleVolumeForDisplay }} μl</dd>
        <dt>Buffer Volume</dt>
        <dd>{{ bufferVolumeForDisplay }} μl</dd>
      </dl>
      <div v-show="belowTargetMolarity" class="alert alert-warning">
        <h5>Insufficient Source Molarity</h5>
        <p>
          The source sample has a molarity of {{ sourceMolarityForDisplay }} nM which is below the target of
          {{ targetMolarityForDisplay }} nM. The transfer as shown will not achieve the target molarity.
        </p>
      </div>
    </div>
  </b-card>
</template>

<script>
import { purposeConfigForTube } from 'shared/tubeHelpers'
import {
  purposeTargetMolarityParameter,
  purposeTargetVolumeParameter,
  purposeMinimumPickParameter,
  tubeMostRecentMolarity,
  calculateTransferVolumes,
} from 'shared/tubeTransferVolumes'

export default {
  name: 'TransferVolumes',
  props: {
    // An object containing purpose configs by UUID.
    purposeConfigs: { type: Object, required: true },

    // The tube that is being transferred from.
    tube: { type: Object, default: null },

    // Whether or not the paired tubes are confirmed.
    confirmedPair: { type: Boolean, default: false },
  },
  computed: {
    purposeConfig() {
      return purposeConfigForTube(this.tube, this.purposeConfigs)
    },
    sourceMolarity() {
      return tubeMostRecentMolarity(this.tube)
    },
    targetMolarity() {
      return purposeTargetMolarityParameter(this.purposeConfig)
    },
    targetVolume() {
      return purposeTargetVolumeParameter(this.purposeConfig)
    },
    transferVolumes() {
      const minimumPick = purposeMinimumPickParameter(this.purposeConfig)
      return calculateTransferVolumes(this.targetMolarity, this.targetVolume, this.sourceMolarity, minimumPick)
    },
    sampleVolumeForDisplay() {
      return this.transferVolumes?.sampleVolume?.toFixed(2)
    },
    bufferVolumeForDisplay() {
      return this.transferVolumes?.bufferVolume?.toFixed(2)
    },
    sourceMolarityForDisplay() {
      return this.sourceMolarity?.toFixed(2)
    },
    targetMolarityForDisplay() {
      return this.targetMolarity?.toFixed(2)
    },
    targetVolumeForDisplay() {
      return this.targetVolume?.toFixed(2)
    },
    belowTargetMolarity() {
      return this.transferVolumes?.belowTarget
    },
    readyToDisplayResult() {
      return this.purposeConfig && this.confirmedPair
    },
  },
}
</script>

<style scoped>
p,
dl {
  font-size: 120%;
}
</style>
