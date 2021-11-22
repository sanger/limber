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
        <lb-plate
          caption="Layout of the new plate"
          :rows="targetRowsNumber"
          :columns="targetColumnsNumber"
          :wells="targetWells"
        />
      </b-card>
    </lb-main-content>
    <lb-sidebar>
      <b-card
        header="Scan tubes"
        header-tag="h3"
      >
        <b-form-group
          label="Scan the tube barcodes into the relevant rack / well coordinates:"
          class="fixed-height-scroll"
        >
          <lb-labware-scan
            v-for="i in sourceTubeNumber"
            :key="i"
            :api="devourApi"
            :label="wellIndexToName(i - 1)"
            :includes="tubeIncludes"
            :fields="tubeFields"
            :validators="scanValidation"
            :colour-index="i"
            :labware-type="'tube'"
            :valid-message="''"
            @change="updateTube(i, $event)"
          />
        </b-form-group>
        <b-alert
          :show="transfersError !== ''"
          variant="danger"
        >
          {{ transfersError }}
        </b-alert>
        <component
          :is="transfersCreatorComponent"
          :valid-transfers="validTransfers"
          @change="transfersCreatorObj = $event"
        />
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
import filterProps from './filterProps'
import transfersCreatorsComponentsMap from './transfersCreatorsComponentsMap'
import MultiStampTubesTransfers from './MultiStampTubesTransfers'
import { transferTubesCreator } from 'shared/transfersCreators'
import Plate from 'shared/components/Plate'
import LabwareScan from 'shared/components/LabwareScan'
import LoadingModal from 'shared/components/LoadingModal'
import devourApi from 'shared/devourApi'
import resources from 'shared/resources'
import { buildTubeObjs } from 'shared/tubeHelpers'
import { transfersForTubes } from 'shared/transfersLayouts'
import { checkDuplicates } from 'shared/components/tubeScanValidators'
import { validScanMessage } from 'shared/components/scanValidators'
import { indexToName } from 'shared/wellHelpers'

export default {
  name: 'MultiStampTubes',
  components: {
    'lb-plate': Plate,
    'lb-labware-scan': LabwareScan,
    'lb-loading-modal': LoadingModal,
    'lb-multi-stamp-tubes-transfers': MultiStampTubesTransfers
  },
  props: {
    // Sequencescape API V2 URL
    sequencescapeApi: { type: String, default: 'http://localhost:3000/api/v2' },

    // Limber plate purpose UUID
    purposeUuid: { type: String, required: true },

    // Limber target Asset URL for posting the transfers
    targetUrl: { type: String, required: true },

    // Name of the transfers creator to use. Transfers Creators translates
    // validTransfers into apiTransfers and potentially modify or add
    // parameters to each transfer
    // (See ./transfersCreatorsComponentsMap.js for components name mapping)
    transfersCreator: { type: String, required: true },

    // Name of the transfers layout to use to determine the position of the
    // destination asset (i.e. target well coordinates).
    // (See ../../shared/transfersLayouts.js for details)
    transfersLayout: { type: String, required: true },

    // Target asset number of rows
    targetRows: { type: String, required: true },

    // Target asset number of columns
    targetColumns: { type: String, required: true },

    // Number of source tubes
    sourceTubes: { type: String, required: true },

    // Object storing response's redirect URL
    locationObj: { default: () => { return location }, type: [Object, Location] },

    allowTubeDuplicates: { type: String, required: true }
  },
  data () {
    return {
      // Array containing objects with scanned tubes, their states and the
      // index of the form input in which they were scanned.
      // Note: Cannot use computed functions as data is invoked before
      tubes: buildTubeObjs(Number.parseInt(this.sourceTubes)),

      // Devour API object to deserialise assets from sequencescape API.
      // (See ../../shared/resources.js for details)
      devourApi: devourApi({ apiUrl: this.sequencescapeApi }, resources),

      // Object containing transfers creator's extraParam function and the
      // state of the transfers (i.e. isValid)
      transfersCreatorObj: {},

      // Flag for toggling loading screen
      loading: false,

      // Message to be shown during loading screen
      progressMessage: ''
    }
  },
  computed: {
    sourceTubeNumber() {
      return Number.parseInt(this.sourceTubes)
    },
    targetRowsNumber() {
      return Number.parseInt(this.targetRows)
    },
    targetColumnsNumber() {
      return Number.parseInt(this.targetColumns)
    },
    valid() {
      return this.unsuitableTubes.length === 0 // None of the tubes are invalid
             && this.validTransfers.length > 0 // We have at least one transfer
             && this.transfersCreatorObj.isValid
    },
    validTubes() {
      return this.tubes.filter( tube => tube.state === 'valid' )
    },
    unsuitableTubes() {
      return this.tubes.filter( tube => !(tube.state === 'valid' || tube.state === 'empty') )
    },
    transfers() {
      return transfersForTubes(this.validTubes)
    },
    validTransfers() {
      return this.transfers.valid
    },
    transfersError() {
      const errorMessages = []
      // TODO: what errors can we have here? duplicate and excess requests seem impossible with tubes
      return errorMessages.join(' and ')
    },
    transfersCreatorComponent() {
      return transfersCreatorsComponentsMap[this.transfersCreator]
    },
    // map of well position to pool index (just a number that controls the colour)
    // {
    //   "A1": 2,
    //   "B4": 9,
    //   ...
    // }
    targetWells() {
      const wells = {}
      for (let i = 0; i < this.validTransfers.length; i++) {
        wells[this.validTransfers[i].targetWell] = {
          pool_index: this.validTransfers[i].tubeObj.index + 1
        }
      }
      return wells
    },
    tubeIncludes() {
      return filterProps.tubeIncludes
    },
    tubeFields() {
      return filterProps.tubeFields
    },
    scanValidation() {
      if (this.allowTubeDuplicates === 'true') {
        return [
          validScanMessage
        ]
      }
      const currTubes = this.tubes.map(tubeItem => tubeItem.labware)
      return [
        checkDuplicates(currTubes)
      ]
    }
  },
  methods: {
    wellIndexToName(index) {
      return indexToName(index, this.targetRowsNumber)
    },
    updateTube(index, data) {
      this.$set(this.tubes, index - 1, {...data, index: index - 1 })
    },
    apiTransfers() {
      // what we want to transfer when cteating the plate
      return transferTubesCreator(this.validTransfers, this.transfersCreatorObj.extraParams)
    },
    createPlate() {
      this.progressMessage = 'Creating plate...'
      this.loading = true
      let payload = {
        plate: {
          parent_uuid: this.validTubes[0].labware.uuid, // TODO: this is just one tube of 96 and assumes A1 is filled, it may not be
          purpose_uuid: this.purposeUuid,
          transfers: this.apiTransfers()
        }
      }
      this.$axios({
        method: 'post',
        url: this.targetUrl,
        headers: {'X-Requested-With': 'XMLHttpRequest'},
        data: payload
      }).then((response) => {
        // Ajax responses automatically follow redirects, which
        // would result in us receiving the full HTML for the child
        // plate here, which we'd then need to inject into the
        // page, and update the history. Instead we don't redirect
        // application/json requests, and redirect the user ourselves.
        this.progressMessage = response.data.message
        this.locationObj.href = response.data.redirect
      }).catch((error) => {
        // Something has gone wrong
        console.error(error)
        this.loading = false
      })
    }
  }
}
</script>

<style>
  .fixed-height-scroll {
    height:460px;
    overflow-y:scroll;
  }
</style>
