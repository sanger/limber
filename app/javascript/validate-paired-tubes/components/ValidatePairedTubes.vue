<template>
  <lb-page>
    <lb-loading-modal
      v-if="loading"
      :message="progressMessage"
    />
    <lb-main-content>
      <lb-transfer-volumes
        :purpose-configs="purposeConfigs"
        :tube="sourceTube.labware"
        :confirmed-pair="allValid"
      />
    </lb-main-content>
    <lb-sidebar>
      <b-card
        header="Validate Tubes"
        header-tag="h3"
      >
        <p class="tv-instructions">
          Scan the source tube and the corresponding destination tube. If they match, the transfer volumes will be shown to the left.
        </p>
        <div class="tube-scan-fields">
          <lb-labware-scan
            key="source"
            ref="sourceScan"
            :api="devourApi"
            label="Source"
            :label-column-span="4"
            :fields="devourFields"
            :includes="devourIncludes"
            :scan-disabled="allValid"
            :validators="sourceTubeValidators"
            labware-type="tube"
            @change="updateSourceTube($event)"
          />
          <lb-labware-scan
            key="destination"
            :api="devourApi"
            label="Destination"
            :label-column-span="4"
            :fields="devourFields"
            :includes="devourIncludes"
            :scan-disabled="allValid"
            :validators="destinationTubeValidators"
            labware-type="tube"
            @change="updateDestinationTube($event)"
          />
        </div>
        <p
          v-show="allValid"
          class="tv-instructions"
        >
          The scanned tubes match. Transfer volumes are now shown. Refresh the page to scan another pair.
        </p>
      </b-card>
    </lb-sidebar>
  </lb-page>
</template>

<script>
import devourApi from 'shared/devourApi'
import filterProps from './filterProps'
import LabwareScan from 'shared/components/LabwareScan'
import LoadingModal from 'shared/components/LoadingModal'
import resources from 'shared/resources'
import TransferVolumes from './TransferVolumes'
import {
  checkId,
  checkMolarityResult,
  checkState,
  checkTransferParameters
} from 'shared/components/tubeScanValidators'

export default {
  name: 'ValidatePairedTubes',
  components: {
    'lb-labware-scan': LabwareScan,
    'lb-loading-modal': LoadingModal,
    'lb-transfer-volumes': TransferVolumes
  },
  props: {
    // Sequencescape API V2 URL.
    sequencescapeApi: { type: String, default: 'http://localhost:3000/api/v2' },

    // Purpose config JSON string of objects keyed by purpose UUIDs.
    purposeConfigJson: { type: String, required: true }
  },
  data () {
    return {
      // Devour API object to deserialise assets from sequencescape API.
      // (See ../../shared/resources.js for details)
      devourApi: devourApi({ apiUrl: this.sequencescapeApi }, resources),

      // Flag for toggling loading screen
      loading: false,

      // Message to be shown during loading screen
      progressMessage: '',

      // The tube scanned as source for the validation.
      // Also the source of transfer volume inputs.
      sourceTube: { state: 'empty', labware: null },

      // The tube scanned as source for the validation.
      // Also the source of transfer volume inputs.
      destinationTube: { state: 'empty', labware: null }
    }
  },
  computed: {
    sourceTubeValidators() {
      return [checkState(['passed']), checkTransferParameters(this.purposeConfigs), checkMolarityResult()]
    },
    destinationTubeValidators() {
      const allowedIdsFromSource = this.sourceTube.labware?.receptacle.downstream_tubes.map(tube => tube.id)
      const allowedIds = (allowedIdsFromSource === undefined) ? [] : allowedIdsFromSource
      return [checkId(allowedIds, 'Does not match the source tube')]
    },
    devourFields() {
      return filterProps.fields
    },
    devourIncludes() {
      return filterProps.includes
    },
    purposeConfigs() {
      return JSON.parse(this.purposeConfigJson)
    },
    allValid() {
      return this.sourceTube.state === 'valid' && this.destinationTube.state === 'valid'
    }
  },
  mounted() {
    this.$refs.sourceScan.focus()
  },
  methods: {
    updateSourceTube(data) {
      this.sourceTube = Object.assign({}, this.sourceTube, data)
    },
    updateDestinationTube(data) {
      this.destinationTube = Object.assign({}, this.destinationTube, data)
    }
  }
}
</script>

<style scoped>
.tv-instructions {
  font-size: 120%;
}

.tube-scan-fields {
  margin: 40px 0px;
}
</style>
