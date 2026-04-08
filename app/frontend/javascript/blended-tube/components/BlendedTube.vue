<template>
  <lb-page>
    <lb-loading-modal v-if="loading" :message="progressMessage" />
    <lb-main-content>
      <b-card bg-variant="dark" text-variant="white" :header="header" header-tag="h3">
        <p>This step accepts two tubes and blends them together.</p>
        <p>To be a valid pair, the tubes must be:</p>
        <ul>
          <li>of an expected purpose and be in state 'passed'</li>
          <li>have the same ancestor plate</li>
          <li>
            must have a matching set of samples (a small proportion of missing samples is acceptable due to failed wells
            earlier).
          </li>
        </ul>
        <p>If valid, the user can click the Blend button to blend the pair together.</p>
        <p>Expected ancestor plate purpose:</p>
        <ul>
          <li>
            <b>{{ ancestorLabwarePurposeName }}</b>
          </li>
        </ul>
        <p>Expected tube purposes to be scanned:</p>
        <ul>
          <li v-for="(purpose, index) in acceptableParentTubePurposesArray" :key="index">
            <b>{{ purpose }}</b>
          </li>
        </ul>
        <p>Child tube created will be of purpose:</p>
        <ul>
          <li>
            <b>{{ childPurposeName }}</b>
          </li>
        </ul>
      </b-card>
    </lb-main-content>
    <lb-sidebar>
      <b-card header="Scan tubes" header-tag="h3">
        <b-form-group class="fixed-height-scroll">
          <lb-pair-tubes-to-blend
            :acceptable-parent-tube-purposes="acceptableParentTubePurposes"
            :ancestor-labware-purpose-name="ancestorLabwarePurposeName"
            :single-ancestor-parent-tube-purpose="singleAncestorParentTubePurpose"
            :api="devourApi"
            @change="updateTubePair($event)"
          />
        </b-form-group>
        <b-button :disabled="!valid" variant="success" @click="createTube()"> Blend </b-button>
      </b-card>
    </lb-sidebar>
  </lb-page>
</template>

<script>
import LoadingModal from '@/javascript/shared/components/LoadingModal.vue'
import PairTubesToBlend from '@/javascript/blended-tube/components/PairTubesToBlend.vue'
import devourApi from '@/javascript/shared/devourApi.js'
import { handleFailedRequest } from '@/javascript/shared/requestHelpers.js'
import resources from '@/javascript/shared/resources.js'
import { transferTubesToTubeCreator } from '@/javascript/shared/transfersCreators.js'

// Blended tube is used in the BGE pipeline where two parent tubes are blended together to create a child tube.

export default {
  name: 'BlendedTube',
  components: {
    'lb-pair-tubes-to-blend': PairTubesToBlend,
    'lb-loading-modal': LoadingModal,
  },
  props: {
    // Sequencescape API V2 URL
    sequencescapeApi: { type: String, default: 'http://localhost:3000/api/v2' },

    // Sequencescape API V2 API key
    sequencescapeApiKey: { type: String, default: 'development' },

    // Limber child tube purpose UUID
    childPurposeUuid: { type: String, required: true },

    // Limber child tube purpose name
    childPurposeName: { type: String, required: true },

    // Limber target Asset URL for posting the transfers
    targetUrl: { type: String, required: true },

    // Object storing response's redirect URL
    locationObj: {
      default: () => {
        return location
      },
      type: [Object, Location],
    },

    // The ancestor plate purpose name which comes from the purpose config
    ancestorLabwarePurposeName: { type: String, required: true },

    // A acceptable list of purpose names that can be scanned
    // If left empty all purposes are acceptable
    // Also referenced as data-acceptable-parent-tube-purposes and data_acceptable_parent_tube_purposes
    // See computed method acceptableParentTubePurposesArray for conversion to array.
    acceptableParentTubePurposes: { type: String, required: false, default: '[]' },

    // The name of the parent tube purpose that will always have a single ancestor plate
    // This must also be in the list of acceptableParentTubePurposes
    // Also referenced as data-single-ancestor-parent-tube-purpose and data_single_ancestor_parent_tube_purpose
    singleAncestorParentTubePurpose: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      // Devour API object to deserialise assets from sequencescape API.
      // (See ../../shared/resources.js for details)
      devourApi: devourApi({ apiUrl: this.sequencescapeApi }, resources, this.sequencescapeApiKey),

      // Flag for toggling loading screen
      loading: false,

      // Message to be shown during loading screen
      progressMessage: '',

      // Tubes passed from blending component
      parentTubes: [],

      // State of the pairing process
      isPairingValid: false,
    }
  },
  computed: {
    // Returns the header for the page
    header() {
      return `Blend Tubes:`
    },
    acceptableParentTubePurposesArray() {
      return JSON.parse(this.acceptableParentTubePurposes)
    },
    // Returns a boolean indicating whether the pair of tubes are valid.
    // Used to enable and disable the 'Blend' button.
    valid() {
      return this.isPairingValid
    },
  },
  methods: {
    updateTubePair(data) {
      if (data.state === 'valid') {
        this.isPairingValid = true
        this.parentTubes = data.pairedTubes.map((tube) => tube.labware)
      } else {
        this.isPairingValid = false
        this.parentTubes = []
      }
    },
    apiTransfers() {
      // what we want to transfer when creating the child tube
      return transferTubesToTubeCreator(this.parentTubes)
    },
    createTube() {
      this.progressMessage = 'Creating blended tube...'
      this.loading = true

      let payload = {
        tube: {
          parent_uuid: this.parentTubes[0].uuid,
          purpose_uuid: this.childPurposeUuid,
          transfers: this.apiTransfers(),
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
          // tube here, which we'd then need to inject into the
          // page, and update the history. Instead we don't redirect
          // application/json requests, and redirect the user ourselves.
          this.progressMessage = response.data.message
          this.locationObj.href = response.data.redirect // eslint-disable-line vue/no-mutating-props
        })
        .catch((error) => {
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
