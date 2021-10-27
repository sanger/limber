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
import { checkDuplicates } from 'shared/components/tubeScanValidators'

export default {
  name: 'TubesToRack',
  components: {
    'lb-labware-scan': LabwareScan,
    'lb-loading-modal': LoadingModal
  },
  props: {
    // Sequencescape API V2 URL
    sequencescapeApi: { type: String, default: 'http://localhost:3000/api/v2' },

    // Number of source tubes
    tubeCount: { type: Number, default: 16 }
  },
  data () {
    return {
      // Array containing objects with scanned tubes, their states and the
      // index of the form input in which they were scanned.
      // Note: Cannot use computed functions as data is invoked before
      tubes: buildTubeObjs(this.tubeCount),

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
      const currTubes = this.tubes.map(tubeItem => tubeItem.labware)
      return [checkDuplicates(currTubes)]
    },
    tubeIncludes() {
      return filterProps.tubeIncludes
    },
    valid() {
      // TODO: DPL-110 identify whether we have a valid submission
      return true
    }
  },
  methods: {
    indexToName(index) {
      const rowIndex = Math.floor(index / 8)
      const colIndex = index - (rowIndex * 8)
      return `${'ABCDEFGH'[rowIndex]}${colIndex + 1}`
    },
    updateTube(index, data) {
      this.$set(this.tubes, index - 1, {...data, index: index - 1 })
    },
    createRack() {}
  }
}
</script>
