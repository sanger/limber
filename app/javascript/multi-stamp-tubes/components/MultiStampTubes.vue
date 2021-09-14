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
        <lb-tube-summary
          v-for="tube in tubes"
          :key="tube.index"
          :state="tube.state"
          :pool_index="tube.index + 1"
          :tube="tube.tube"
        />
      </b-card>
    </lb-main-content>
    <lb-sidebar>
      <b-card
        header="Add tubes"
        header-tag="h3"
      >
        <b-form-group label="Scan in the tubes you wish to use">
          <lb-tube-scan
            v-for="i in sourceTubeNumber"
            :key="i"
            :api="devourApi"
            :label="wellIndexToName(i - 1)"
            :includes="tubeIncludes"
            :fields="tubeFields"
            :validators="scanValidation"
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
import TubeSummary from './TubeSummary'
import filterProps from './filterProps'
import transfersCreatorsComponentsMap from './transfersCreatorsComponentsMap'
import MultiStampTubesTransfers from './MultiStampTubesTransfers'
import { transferTubesCreator } from 'shared/transfersCreators'
import Plate from 'shared/components/Plate'
import TubeScan from 'shared/components/TubeScan'
import LoadingModal from 'shared/components/LoadingModal'
import devourApi from 'shared/devourApi'
import resources from 'shared/resources'
import { buildTubeObjs } from 'shared/tubeHelpers'
import { transfersForTubes } from 'shared/transfersLayouts'
import { checkDuplicates } from 'shared/components/tubeScanValidators'
import { indexToName } from 'shared/wellHelpers'

export default {
  name: 'MultiStampTubes',
  components: {
    'lb-plate': Plate,
    'lb-tube-scan': TubeScan,
    'lb-tube-summary': TubeSummary,
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
    locationObj: { default: () => { return location }, type: [Object, Location] }
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
      console.log("DEBUG: in sourceTubeNumber")
      return Number.parseInt(this.sourceTubes)
    },
    targetRowsNumber() {
      console.log("DEBUG: in targetRowsNumber")
      return Number.parseInt(this.targetRows)
    },
    targetColumnsNumber() {
      console.log("DEBUG: in targetColumnsNumber")
      return Number.parseInt(this.targetColumns)
    },
    valid() {
      console.log("DEBUG: in valid")
      return this.unsuitableTubes.length === 0 // None of the tubes are invalid
             && this.validTransfers.length > 0 // We have at least one transfer
             && this.transfersCreatorObj.isValid
    },
    validTubes() {
      console.log("DEBUG: in validTubes")
      return this.tubes.filter( tube => tube.state === 'valid' )
    },
    unsuitableTubes() {
      console.log("DEBUG: in unsuitableTubes")
      return this.tubes.filter( tube => !(tube.state === 'valid' || tube.state === 'empty') )
    },
    transfers() {
      console.log("DEBUG: in transfers")
      return transfersForTubes(this.validTubes)
    },
    validTransfers() {
      console.log("DEBUG: in validTransfers")
      return this.transfers.valid
    },
    transfersError() {
      console.log("DEBUG: in transfersError")
      const errorMessages = []
      // TODO: what errors can we have here? duplicate and excess requests seem impossible with tubes
      return errorMessages.join(' and ')
    },
    transfersCreatorComponent() {
      console.log("DEBUG: in transfersCreatorComponent")
      return transfersCreatorsComponentsMap[this.transfersCreator]
    },
    targetWells() {
      console.log("DEBUG: in targetWells")
      const wells = {}
      for (let i = 0; i < this.validTransfers.length; i++) {
        wells[this.validTransfers[i].targetWell] = {
          pool_index: this.validTransfers[i].tubeObj.index + 1
        }
      }
      return wells
    },
    tubeIncludes() {
      console.log("DEBUG: in tubeIncludes")
      return filterProps.tubeIncludes
    },
    tubeFields() {
      console.log("DEBUG: in tubeFields")
      return filterProps.tubeFields
    },
    scanValidation() {
      console.log("DEBUG: in scanValidation")
      const currTubes = this.tubes.map(tubeItem => tubeItem.tube)
      return [
        checkDuplicates(currTubes)
      ]
    }
  },
  methods: {
    wellIndexToName(index) {
      console.log("DEBUG: in wellIndexToName")
      return indexToName(index, this.targetRowsNumber)
    },
    updateTube(index, data) {
      console.log("DEBUG: in updateTube")
      this.$set(this.tubes, index - 1, {...data, index: index - 1 })
    },
    apiTransfers() {
      console.log("DEBUG: in apiTransfers")
      // what we want to transfer when cteating the plate
      return transferTubesCreator(this.validTransfers, this.transfersCreatorObj.extraParams)
    },
    createPlate() {
      console.log("DEBUG: in createPlate")
      this.progressMessage = 'Creating plate...'
      this.loading = true
      let payload = {
        plate: {
          parent_uuid: this.validTubes[0].tube.uuid, // TODO: this is just one tube of 96 and assumes A1 is filled, it may not be
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
