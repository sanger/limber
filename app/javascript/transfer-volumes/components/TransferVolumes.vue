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
            :api="devourApi"
            label="Pool XP"
            :labelCols="3"
            :fields="tubeFields"
            :includes="tubeIncludes"
            :validators="scanValidators"
            :labware-type="'tube'"
            @change="updateTube(0, $event)"
          />
          <lb-labware-scan
            key="destination"
            :api="devourApi"
            label="Pool Norm"
            :labelCols="3"
            :fields="tubeFields"
            :includes="tubeIncludes"
            :validators="scanValidators"
            :labware-type="'tube'"
            @change="updateTube(1, $event)"
          />
        </div>
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
import { buildTubeObjs } from 'shared/tubeHelpers'
import { checkDuplicates, checkMatchingPurposes } from 'shared/components/tubeScanValidators'

export default {
  name: 'TransferVolumes',
  components: {
    'lb-labware-scan': LabwareScan,
    'lb-loading-modal': LoadingModal
  },
  props: {
    // Sequencescape API V2 URL
    sequencescapeApi: { type: String, default: 'http://localhost:3000/api/v2' },
  },
  data () {
    return {
      // Array containing objects with scanned tubes, their states and the
      // index of the form input in which they were scanned.
      tubes: buildTubeObjs(2),

      // Devour API object to deserialise assets from sequencescape API.
      // (See ../../shared/resources.js for details)
      devourApi: devourApi({ apiUrl: this.sequencescapeApi }, resources),

      // Flag for toggling loading screen
      loading: false,

      // Message to be shown during loading screen
      progressMessage: ''
    }
  },
  computed: {
    scanValidators() {
      const allTubes = this.tubes.map(tubeItem => tubeItem.labware)
      return [checkDuplicates(allTubes), checkMatchingPurposes(this.firstTubePurpose)]
    },
    tubeFields() {
      return filterProps.tubeFields
    },
    tubeIncludes() {
      return filterProps.tubeIncludes
    },
    firstTubePurpose() {
      return this.validTubes[0]?.labware.purpose
    },
    unsuitableTubes() {
      return this.tubes.filter( tube => !(tube.state === 'valid' || tube.state === 'empty') )
    },
    valid() {
      return this.validTubes.length > 0 &&      // At least one tube is validated
             this.unsuitableTubes.length === 0  // None of the tubes are invalid
    },
    validTubes() {
      return this.tubes.filter( tube => tube.state === 'valid' )
    }
  },
  methods: {
    updateTube(index, data) {
      this.$set(this.tubes, index - 1, {...data, index: index - 1 })
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
