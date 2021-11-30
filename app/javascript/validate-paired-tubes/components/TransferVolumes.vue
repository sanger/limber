<template>
  <b-card
    header="Transfer Volumes"
    header-tag="h3"
  >
    <p v-show="!readyToDisplayResult">
      Once paired tubes are scanned in, transfer volumes will be shown here.
    </p>
    <div v-show="readyToDisplayResult">
      <p>
        The transfer volumes shown are to make a {{ targetVolume }} μl / {{ targetMolarity }} nM solution.
      </p>
      <dl class="row metadata">
        <dt>Sample Volume</dt>
        <dd>{{ sampleVolume }} μl</dd>
        <dt>Buffer Volume</dt>
        <dd>{{ bufferVolume }} μl</dd>
      </dl>
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
    confirmedPair: { type: Boolean, default: false }
  },
  computed: {
    purposeConfig() {
      return purposeConfigForTube(this.tube, this.purposeConfigs)
    },
    targetMolarity() {
      return purposeTargetMolarityParameter(this.purposeConfig)
    },
    targetVolume() {
      return purposeTargetVolumeParameter(this.purposeConfig)
    },
    transferVolumes() {
      const sourceMolarity = tubeMostRecentMolarity(this.tube)
      const minimumPick = purposeMinimumPickParameter(this.purposeConfig)
      return calculateTransferVolumes(this.targetMolarity, this.targetVolume, sourceMolarity, minimumPick)
    },
    sampleVolume() {
      return this.transferVolumes.sampleVolume?.toFixed(1)
    },
    bufferVolume() {
      return this.transferVolumes.bufferVolume?.toFixed(1)
    },
    readyToDisplayResult() {
      return this.purposeConfig && this.confirmedPair
    }
  }
}
</script>

<style scoped>
  p {
    font-size: 120%;
  }
</style>
