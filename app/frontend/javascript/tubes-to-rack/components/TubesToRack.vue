<!--
  This is partially complete work and needs a few more pieces putting into place:
  - Swap out the UI of the tube rack for a component James G was working on.
  - Parse the tubes added to the rack into the correct format and hook up the
    API call to the V2 SequenceScape endpoint for tube racks.
  - Review the validations applied here and adjust if needed.
-->

<template>
  <lb-page>
    <lb-loading-modal v-if="loading" :message="progressMessage" />
    <lb-main-content>
      <b-card bg-variant="dark" text-variant="white">
        <h3>Tube rack UI goes here</h3>
        <p>
          Scanned tubes will appear in a UI representation of the tube rack. This will be similar in function to the
          plate UI but will be capable of opening the tube information page when viewed after creation.
        </p>
      </b-card>
    </lb-main-content>
    <lb-sidebar>
      <b-card header="Scan tubes" header-tag="h3">
        <b-form-group label="Scan the tube barcodes into the relevant rack coordinates:" class="fixed-height-scroll">
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
        <hr />
        <b-button :disabled="!valid" variant="success" @click="createRack()"> Create </b-button>
      </b-card>
    </lb-sidebar>
  </lb-page>
</template>

<script>
import LabwareScan from '@/javascript/shared/components/LabwareScan.vue'
import LoadingModal from '@/javascript/shared/components/LoadingModal.vue'
import { checkDuplicates, checkMatchingPurposes } from '@/javascript/shared/components/tubeScanValidators.js'
import devourApi from '@/javascript/shared/devourApi.js'
import { handleFailedRequest } from '@/javascript/shared/requestHelpers.js'
import resources from '@/javascript/shared/resources.js'
import { buildTubeObjs } from '@/javascript/shared/tubeHelpers.js'
import { indexToName } from '@/javascript/shared/wellHelpers.js'
import filterProps from './filterProps.js'

export default {
  name: 'TubesToRack',
  components: {
    'lb-labware-scan': LabwareScan,
    'lb-loading-modal': LoadingModal,
  },
  props: {
    // Sequencescape API V2 URL
    sequencescapeApi: { type: String, default: 'http://localhost:3000/api/v2' },

    // Sequencescape API V2 API key
    sequencescapeApiKey: { type: String, default: 'development' },

    // Width of tube rack
    rackWidth: { type: Number, default: 8 },

    // Height of tube rack
    rackHeight: { type: Number, default: 2 },

    // Limber target Asset URL for posting the transfers
    targetUrl: { type: String, required: true },
  },
  data() {
    return {
      // Array containing objects with scanned tubes, their states and the
      // index of the form input in which they were scanned.
      // Note: Cannot use computed functions as data is invoked before.
      tubes: buildTubeObjs(this.rackWidth * this.rackHeight),

      // Devour API object to deserialise assets from sequencescape API.
      // (See ../../shared/resources.js for details)
      devourApi: devourApi({ apiUrl: this.sequencescapeApi }, resources, this.sequencescapeApiKey),

      // Flag for toggling loading screen
      loading: false,

      // Message to be shown during loading screen
      progressMessage: '',
    }
  },
  computed: {
    scanValidators() {
      const allTubes = this.tubes.map((tubeItem) => tubeItem.labware)
      return [checkDuplicates(allTubes), checkMatchingPurposes(this.firstTubePurpose)]
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
    firstTubePurpose() {
      return this.validTubes[0]?.labware.purpose
    },
    unsuitableTubes() {
      return this.tubes.filter((tube) => !(tube.state === 'valid' || tube.state === 'empty'))
    },
    valid() {
      return (
        this.validTubes.length > 0 && // At least one tube is validated
        this.unsuitableTubes.length === 0
      ) // None of the tubes are invalid
    },
    validTubes() {
      return this.tubes.filter((tube) => tube.state === 'valid')
    },
  },
  methods: {
    indexToName(index) {
      return indexToName(index, this.rackHeight)
    },
    updateTube(index, data) {
      this.tubes[index - 1] = { ...data, index: index - 1 }
    },
    createRack() {
      this.progressMessage = 'Creating tube rack...'
      this.loading = true
      let payload = {
        tube_rack: {
          purpose_uuid: this.firstTubePurpose.uuid,
        },
      }
      this.$axios({
        method: 'post',
        url: this.targetUrl,
        headers: { 'X-Requested-With': 'XMLHttpRequest' },
        data: payload,
      })
        .then((response) => {
          // Ajax responses automatically follow redirects, which
          // would result in us receiving the full HTML for the child
          // plate here, which we'd then need to inject into the
          // page, and update the history. Instead we don't redirect
          // application/json requests, and redirect the user ourselves.
          this.progressMessage = response.data.message
          this.locationObj.href = response.data.redirect
        })
        .catch((error) => {
          // Something has gone wrong
          handleFailedRequest(error)
          this.loading = false
        })
    },
  },
}
</script>

<style>
.fixed-height-scroll {
  height: 460px;
  overflow-y: scroll;
}
</style>
