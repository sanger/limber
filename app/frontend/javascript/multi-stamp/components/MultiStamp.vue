<template>
  <lb-page>
    <lb-loading-modal v-if="loading" :message="progressMessage" />
    <lb-main-content>
      <b-card bg-variant="dark" text-variant="white">
        <lb-plate-summary
          v-for="plate in plates"
          :key="plate.index"
          :state="plate.state"
          :colour_index="plate.index + 1"
          :plate="plate.plate"
        />
        <lb-plate caption="New Plate" :rows="targetRowsNumber" :columns="targetColumnsNumber" :wells="targetWells" />
      </b-card>
    </lb-main-content>
    <lb-sidebar>
      <b-card header="Add plates" header-tag="h3">
        <b-form-group label="Scan in the plates you wish to use">
          <lb-plate-scan
            v-for="i in sourcePlateNumber"
            :key="i"
            :api="devourApi"
            :label="'Plate ' + i"
            :includes="plateIncludes"
            :fields="plateFields"
            :validators="scanValidation"
            @change="updatePlate(i, $event)"
          />
        </b-form-group>
        <b-alert :model-value="transfersError !== ''" variant="danger">
          {{ transfersError }}
        </b-alert>
        <component
          :is="requestsFilterComponent"
          :requests-with-plates="requestsWithPlates"
          @change="requestsWithPlatesFiltered = $event"
        />
        <component
          :is="transfersCreatorComponent"
          :default-volume="defaultVolumeNumber"
          :valid-transfers="validTransfers"
          @update:model-value="transfersCreatorObj = $event"
        />
        <b-button :disabled="!valid" variant="success" @click="createPlate()"> Create </b-button>
      </b-card>
    </lb-sidebar>
  </lb-page>
</template>

<script>
import LabwareScan from '@/javascript/shared/components/LabwareScan.vue'
import LoadingModal from '@/javascript/shared/components/LoadingModal.vue'
import Plate from '@/javascript/shared/components/Plate.vue'
import {
  checkDuplicates,
  checkSize,
  checkForUnacceptablePlatePurpose,
} from '@/javascript/shared/components/plateScanValidators.js'
import devourApi from '@/javascript/shared/devourApi.js'
import buildPlateObjs from '@/javascript/shared/plateHelpers.js'
import { handleFailedRequest, requestIsActive, requestsFromPlates } from '@/javascript/shared/requestHelpers.js'
import resources from '@/javascript/shared/resources.js'
import { transferPlatesToPlatesCreator } from '@/javascript/shared/transfersCreators.js'
import { transfersFromRequests } from '@/javascript/shared/transfersLayouts.js'
import MultiStampTransfers from './MultiStampTransfers.vue'
import NullFilter from './NullFilter.vue'
import PlateSummary from './PlateSummary.vue'
import PrimerPanelFilter from './PrimerPanelFilter.vue'
import VolumeTransfers from './VolumeTransfers.vue'
import filterProps from './filterProps.js'
import transfersCreatorsComponentsMap from './transfersCreatorsComponentsMap.js'

export default {
  name: 'MultiStamp',
  components: {
    'lb-plate': Plate,
    'lb-plate-scan': LabwareScan,
    'lb-plate-summary': PlateSummary,
    'lb-loading-modal': LoadingModal,
    'lb-primer-panel-filter': PrimerPanelFilter,
    'lb-null-filter': NullFilter,
    'lb-multi-stamp-transfers': MultiStampTransfers,
    'lb-volume-transfers': VolumeTransfers,
  },
  props: {
    // Sequencescape API V2 URL
    sequencescapeApi: { type: String, default: 'http://localhost:3000/api/v2' },

    // Sequencescape API V2 API key
    sequencescapeApiKey: { type: String, default: 'development' },

    // Limber plate purpose UUID
    purposeUuid: { type: String, required: true },

    // Limber target Asset URL for posting the transfers
    targetUrl: { type: String, required: true },

    // Name of the requests filter configuration to use. Requests filters takes
    // an array of requests (requestsWithPlates) and return a filtered array
    // (requestsWithPlatesFiltered).
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

    // Number of source plates
    sourcePlates: { type: String, required: true },

    // Object storing response's redirect URL
    locationObj: {
      default: () => {
        return location
      },
      type: [Object, Location],
    },

    // Default volume to define in the UI for the volume control
    defaultVolume: { type: String, required: false, default: null },

    // Acceptable plate purpose names that can be used as source plates.
    // Defines a prop `acceptablePurposes` that accepts a string. It is optional and
    // defaults to a string representation of an array '[]' if not provided.
    // e.g. "['PurposeA', 'PurposeB']"
    // See computed method acceptablePurposesArray for conversion to array.
    // If present is used in scanValidation to check if the user has scanned an
    // a plate of the correct type.
    acceptablePurposes: { type: String, required: false, default: '[]' },
  },
  data() {
    return {
      // Array containing objects with scanned plates, their states and the
      // index of the form input in which they were scanned.
      // Note: Cannot use computed functions as data is invoked before.
      // Initial structure (4 for quadstamp):
      // [
      //   { "index": 0, "plate": null, "state": "empty" },
      //   { "index": 1, "plate": null, "state": "empty" },
      //   ...
      // ]
      plates: buildPlateObjs(Number.parseInt(this.sourcePlates)),

      // Devour API object to deserialise assets from sequencescape API.
      // (See ../../shared/resources.js for details)
      devourApi: devourApi({ apiUrl: this.sequencescapeApi }, resources, this.sequencescapeApiKey),

      // Array of filtered requestsWithPlates emitted by the request filter
      requestsWithPlatesFiltered: [],

      // Object containing transfers creator's extraParam function and the
      // state of the transfers (i.e. isValid)
      transfersCreatorObj: {},

      // Flag for toggling loading screen
      loading: false,

      // Message to be shown during loading screen
      progressMessage: '',
    }
  },
  computed: {
    defaultVolumeNumber() {
      if (typeof this.defaultVolume === 'undefined' || this.defaultVolume === null) {
        return null
      }
      return Number.parseInt(this.defaultVolume)
    },
    sourcePlateNumber() {
      return Number.parseInt(this.sourcePlates)
    },
    targetRowsNumber() {
      return Number.parseInt(this.targetRows)
    },
    targetColumnsNumber() {
      return Number.parseInt(this.targetColumns)
    },
    acceptablePurposesArray() {
      return JSON.parse(this.acceptablePurposes)
    },
    valid() {
      return (
        this.unsuitablePlates.length === 0 && // None of the plates are invalid
        this.validTransfers.length > 0 && // We have at least one transfer
        this.excessTransfers.length === 0 && // No excess transfers
        this.duplicatedTransfers.length === 0 && // No duplicated transfers
        this.transfersCreatorObj.isValid
      )
    },
    validPlates() {
      return this.plates.filter((plate) => plate.state === 'valid')
    },
    unsuitablePlates() {
      return this.plates.filter((plate) => !(plate.state === 'valid' || plate.state === 'empty'))
    },
    requestsWithPlates() {
      const requestsFromPlatesArray = requestsFromPlates(this.validPlates)
      const requestsWithPlatesArray = []
      for (let i = 0; i < requestsFromPlatesArray.length; i++) {
        if (requestIsActive(requestsFromPlatesArray[i].request)) {
          requestsWithPlatesArray.push(requestsFromPlatesArray[i])
        }
      }
      return requestsWithPlatesArray
    },
    transfers() {
      return transfersFromRequests(this.requestsWithPlatesFiltered, this.transfersLayout)
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
        let sourceBarcodes = new Set()
        this.duplicatedTransfers.forEach((transfer) => {
          sourceBarcodes.add(transfer.plateObj.plate.labware_barcode.human_barcode)
        })

        const msg =
          'This would result in multiple transfers into the same well. Check if the source plates (' +
          [...sourceBarcodes].join(', ') +
          ') have more than one active submission.'
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
        wells[this.validTransfers[i].targetWell] = {
          colour_index: this.validTransfers[i].plateObj.index + 1,
        }
      }
      return wells
    },
    requestsFilterComponent() {
      return filterProps[this.requestsFilter].requestsFilter
    },
    plateIncludes() {
      return filterProps[this.requestsFilter].plateIncludes
    },
    plateFields() {
      return filterProps[this.requestsFilter].plateFields
    },
    scanValidation() {
      const currPlates = this.plates.map((plateItem) => plateItem.plate)
      return [
        checkSize(12, 8),
        checkDuplicates(currPlates),
        checkForUnacceptablePlatePurpose(this.acceptablePurposesArray),
      ]
    },
  },
  methods: {
    updatePlate(index, data) {
      this.plates[index - 1] = { ...data, index: index - 1 }
    },
    apiTransfers() {
      return transferPlatesToPlatesCreator(this.validTransfers, this.transfersCreatorObj.extraParams)
    },
    createPlate() {
      this.progressMessage = 'Creating plate...'
      this.loading = true
      let payload = {
        plate: {
          parent_uuid: this.validPlates[0].plate.uuid,
          purpose_uuid: this.purposeUuid,
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
          // plate here, which we'd then need to inject into the
          // page, and update the history. Instead we don't redirect
          // application/json requests, and redirect the user ourselves.
          this.progressMessage = response.data.message
          this.locationObj.href = response.data.redirect // eslint-disable-line vue/no-mutating-props
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
