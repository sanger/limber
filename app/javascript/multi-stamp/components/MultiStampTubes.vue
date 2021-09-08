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
        <lb-tube-summary
          v-for="tube in tubes"
          :key="tube.index"
          :state="tube.state"
          :pool_index="tube.index + 1"
          :tube="tube.tube"
        />
        <lb-plate
          caption="New Plate"
          :rows="targetRowsNumber"
          :columns="targetColumnsNumber"
          :wells="targetWells"
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
            :label="'Tube ' + i"
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
          :is="requestsFilterComponent"
          :requests-with-tubes="requestsWithTubes"
          @change="requestsWithTubesFiltered = $event"
        />
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
// TODO: do we need primer panels?
// import PrimerPanelFilter from './PrimerPanelFilter'
import NullFilterTubes from './NullFilterTubes'
import transfersCreatorsComponentsMap from './transfersCreatorsComponentsMap'
import MultiStampTransfers from './MultiStampTransfers'
// TODO: do we need a volume?
// import VolumeTransfers from './VolumeTransfers'
import { transferTubesCreator } from 'shared/transfersCreators'
import Plate from 'shared/components/Plate'
import TubeScan from 'shared/components/TubeScan'
import LoadingModal from 'shared/components/LoadingModal'
import devourApi from 'shared/devourApi'
import resources from 'shared/resources'
import { buildTubeObjs } from 'shared/tubeHelpers'
import { requestIsActive, requestsFromTubes } from 'shared/requestHelpers'
import { transfersFromRequests } from 'shared/transfersLayouts'
import { checkDuplicates } from 'shared/components/tubeScanValidators'

export default {
  name: 'MultiStampTubes',
  components: {
    'lb-plate': Plate,
    'lb-tube-scan': TubeScan,
    'lb-tube-summary': TubeSummary,
    'lb-loading-modal': LoadingModal,
    // 'lb-primer-panel-filter': PrimerPanelFilter,
    'lb-null-filter': NullFilterTubes,
    'lb-multi-stamp-transfers': MultiStampTransfers
    // 'lb-volume-transfers': VolumeTransfers
  },
  props: {
    // Sequencescape API V2 URL
    sequencescapeApi: { type: String, default: 'http://localhost:3000/api/v2' },

    // Limber plate purpose UUID
    purposeUuid: { type: String, required: true },

    // Limber target Asset URL for posting the transfers
    targetUrl: { type: String, required: true },

    // Name of the requests filter configuration to use. Requests filters takes
    // an array of requests (requestsWithTubes) and return a filtered array
    // (requestsWithTubesFiltered).
    // (See configurations in ./filterProps.js)
    requestsFilter: { type: String, required: true },

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

      // Array of filtered requestsWithTubes emitted by the request filter
      requestsWithTubesFiltered: [],

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
             && this.excessTransfers.length === 0 // No excess transfers
             && this.duplicatedTransfers.length === 0 // No duplicated transfers
             && this.transfersCreatorObj.isValid
    },
    validTubes() {
      return this.tubes.filter( tube => tube.state === 'valid' )
    },
    unsuitableTubes() {
      return this.tubes.filter( tube => !(tube.state === 'valid' || tube.state === 'empty') )
    },
    requestsWithTubes() {
      const requestsFromTubesArray = requestsFromTubes(this.validTubes)
      const requestsWithTubesArray = []
      for (let i = 0; i < requestsFromTubesArray.length; i++) {
        if (requestIsActive(requestsFromTubesArray[i].request)) {
          requestsWithTubesArray.push(requestsFromTubesArray[i])
        }
      }
      return requestsWithTubesArray
    },
    transfers() {
      return transfersFromRequests(this.requestsWithTubesFiltered, this.transfersLayout)
    },
    validTransfers() {
      return this.transfers.valid
    },
    duplicatedTransfers() {
      return this.transfers.duplicated
    },
    excessTransfers() {
      return this.validTransfers.slice(this.targetRowsNumber * this.targetColumnsNumber)
    },
    transfersError() {
      const errorMessages = []
      if (this.duplicatedTransfers.length > 0) {
        var sourceBarcodes = new Set()
        this.duplicatedTransfers.forEach(transfer => {
          sourceBarcodes.add(transfer.tubeObj.tube.labware_barcode.human_barcode)
        })

        const msg = 'This would result in multiple transfers into the same well. Check if the source tubes ('
                    + [...sourceBarcodes].join(', ')
                    + ') have more than one active submission.'
        errorMessages.push(msg)
      }
      if (this.excessTransfers.length > 0) {
        errorMessages.push('excess transfers')
      }
      return errorMessages.join(' and ')
    },
    transfersCreatorComponent() {
      return transfersCreatorsComponentsMap[this.transfersCreator]
    },
    targetWells() {
      const wells = {}
      for (let i = 0; i < this.validTransfers.length; i++) {
        console.log("*** validTransfers[i] ***", this.validTransfers[i])
        console.log("*** tubeObj ***", this.validTransfers[i].tubeObj)
        wells[this.validTransfers[i].targetWell] = {
          pool_index: this.validTransfers[i].tubeObj.index + 1
        }
        console.log("well:", wells[this.validTransfers[i].targetWell])
      }
      return wells
    },
    requestsFilterComponent() {
      return filterProps[this.requestsFilter].requestsFilter
    },
    tubeIncludes() {
      return filterProps[this.requestsFilter].tubeIncludes
    },
    tubeFields() {
      return filterProps[this.requestsFilter].tubeFields
    },
    scanValidation() {
      const currTubes = this.tubes.map(tubeItem => tubeItem.tube)
      return [
        checkDuplicates(currTubes)
      ]
    }
  },
  methods: {
    updateTube(index, data) {
      this.$set(this.tubes, index - 1, {...data, index: index - 1 })
      console.log("*** this.tubes ***", this.tubes)
    },
    apiTransfers() {
      return transferTubesCreator(this.validTransfers, this.transfersCreatorObj.extraParams)
    },
    createPlate() {
      this.progressMessage = 'Creating plate...'
      this.loading = true
      let payload = {
        plate: {
          parent_uuid: this.validTubes[0].tube.uuid,
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
        console.log(error)
        this.loading = false
      })
    }
  }
}
</script>
