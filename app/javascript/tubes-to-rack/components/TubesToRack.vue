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
        <h3>Tube rack UI goes here</h3>
        <p>
          Scanned tubes will appear in a UI representation of the tube rack.
          This will be similar in function to the plate UI but will be capable
          of opening the tube information page when viewed after creation.
        </p>
      </b-card>
    </lb-main-content>
    <lb-sidebar>
      <b-card
        header="Scan tubes"
        header-tag="h3"
      >
        <b-form-group
          label="Scan the tube barcodes into the relevant rack coordinates:"
          style="position:relative; height:460px; overflow-y:scroll;"
        >
          <lb-labware-scan
            v-for="i in tubeCount"
            :key="i"
            :api="devourApi"
            :label="indexToName(i - 1)"
            :fields="tubeFields"
            :includes="tubeIncludes"
            :validators="scanValidators"
            :colour-index="i"
            :labware-type="'tube'"
            :valid-message="''"
            @change="updateTube(i, $event)"
          />
        </b-form-group>
        <hr>
        <b-button
          :disabled="!valid"
          variant="success"
          @click="createRack()"
        >
          Create
        </b-button>
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
import { indexToName } from 'shared/wellHelpers.js'

export default {
  name: 'TubesToRack',
  components: {
    'lb-labware-scan': LabwareScan,
    'lb-loading-modal': LoadingModal
  },
  props: {
    // Sequencescape API V2 URL
    sequencescapeApi: { type: String, default: 'http://localhost:3000/api/v2' },

    // Width of tube rack
    rackWidth: { type: Number, default: 8 },

    // Height of tube rack
    rackHeight: { type: Number, default: 2 }
  },
  data () {
    return {
      // Array containing objects with scanned tubes, their states and the
      // index of the form input in which they were scanned.
      // Note: Cannot use computed functions as data is invoked before.
      tubes: buildTubeObjs(this.rackWidth * this.rackHeight),

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
      const firstPurpose = this.validTubes[0]?.labware.purpose
      return [checkDuplicates(allTubes), checkMatchingPurposes(firstPurpose)]
    },
    tubeCount() {
      return this.rackWidth * this.rackHeight
    },
    tubeFields() {
      return filterProps.tubeFields
    },
    tubeIncludes() {
      return filterProps.tubeIncludes
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
    indexToName(index) {
      return indexToName(index, this.rackHeight)
    },
    updateTube(index, data) {
      this.$set(this.tubes, index - 1, {...data, index: index - 1 })
    },
    createRack() {}
  }
}
</script>
