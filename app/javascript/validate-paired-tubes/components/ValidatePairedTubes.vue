<template>
  <lb-page>
    <lb-loading-modal
      v-if="loading"
      :message="progressMessage"
    />
    <lb-main-content>
      <b-card
        bg-variant="dark"
        text-variant="white"
      >
        <h3>Scanned tubes will be shown here!</h3>
        <p>
          Scanned tubes will appear here for the user to be able to visualise
          what they've been scanning on the right.
        </p>
      </b-card>
    </lb-main-content>
    <lb-sidebar>
      <b-card
        header="Validate Tubes"
        header-tag="h3"
      >
        <p class="vt-instructions">Scan the LTHR-384 Pool XP tube and the corresponding LB Lib Pool Norm tube. If they match, the transfer volumes will be shown below.</p>
        <div class="tube-scan-fields">
          <lb-labware-scan
            key="source"
            ref="sourceScan"
            :api="devourApi"
            label="Pool XP"
            :labelCols="3"
            :fields="devourFields"
            :includes="devourIncludes"
            :validators="scanValidators"
            :labware-type="'tube'"
            @change="updateSourceTube($event)"
          />
          <lb-labware-scan
            key="destination"
            :api="devourApi"
            label="Pool Norm"
            :labelCols="3"
            :fields="devourFields"
            :includes="devourIncludes"
            :validators="scanValidators"
            :labware-type="'tube'"
            @change="updateDestinationTube($event)"
          />
        </div>
      </b-card>
      <lb-transfer-volumes />
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
    scanValidators() {
      return []
    },
    devourFields() {
      return filterProps.fields
    },
    devourIncludes() {
      return filterProps.includes
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

<style>
.vt-instructions {
  font-size: 120%;
}

.tube-scan-fields {
  margin: 40px 0px;
}
</style>
