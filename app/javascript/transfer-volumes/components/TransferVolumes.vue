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
        <h4>Scan the tubes to validate and perform a transfer on:</h4>
        <lb-labware-scan
          key="source"
          :api="devourApi"
          label="Source"
          :fields="tubeFields"
          :includes="tubeIncludes"
          :validators="scanValidators"
          colour-index="1"
          :labware-type="'tube'"
          @change="updateTube(0, $event)"
        />
        <lb-labware-scan
          key="destination"
          :api="devourApi"
          label="Destination"
          :fields="tubeFields"
          :includes="tubeIncludes"
          :validators="scanValidators"
          colour-index="2"
          :labware-type="'tube'"
          @change="updateTube(1, $event)"
        />
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
  props: {},
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
