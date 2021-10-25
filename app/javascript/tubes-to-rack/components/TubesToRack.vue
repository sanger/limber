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
        <h1>Tube Rack</h1>
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
            :colour-index="i"
            :labware-type="'tube'"
            :valid-message="''"
          />
        </b-form-group>
        <hr>
        <b-button
          :disabled="!valid"
          variant="success"
          @click="createPlate()"
        >
          Create
        </b-button>
      </b-card>
    </lb-sidebar>
  </lb-page>
</template>

<script>
import devourApi from 'shared/devourApi'
import LoadingModal from 'shared/components/LoadingModal'
import LabwareScan from 'shared/components/LabwareScan'
import resources from 'shared/resources'

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
    }
  }
}
</script>
