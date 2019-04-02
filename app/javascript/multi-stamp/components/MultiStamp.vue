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
        <lb-plate-summary
          v-for="plate in plates"
          :key="plate.index"
          :state="plate.state"
          :pool_index="plate.index + 1"
          :plate="plate.plate"
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
        header="Add plates"
        header-tag="h3"
      >
        <b-form-group label="Scan in the plates you wish to use">
          <lb-plate-scan
            v-for="i in sourcePlateNumber"
            :key="i"
            :api="devourApi"
            :label="'Plate ' + i"
            :includes="plateIncludes"
            :fields="plateFields"
            :validation="scanValidation(i-1)"
            @change="updatePlate(i, $event)"
          />
        </b-form-group>
        <component
          :is="requestsFilter"
          :requests-with-plates="requestsWithPlates"
          @change="requestsWithPlatesFiltered = $event"
        />
        <b-alert
          :show="transfersError !== ''"
          variant="danger"
        >
          {{ transfersError }}
        </b-alert>
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
import PlateSummary from './PlateSummary'
import filterProps from './filterProps'
import PrimerPanelFilter from './PrimerPanelFilter'
import NullFilter from './NullFilter'
import Plate from 'shared/components/Plate'
import PlateScan from 'shared/components/PlateScan'
import LoadingModal from 'shared/components/LoadingModal'
import devourApi from 'shared/devourApi'
import resources from 'shared/resources'
import builPlateObjs from 'shared/plateHelpers'
import { requestIsActive, requestsFromPlates } from 'shared/requestHelpers'
import { transfersFromRequests } from 'shared/transfersLayouts'
import { checkSize, checkDuplicates, checkOverflows, aggregate } from 'shared/components/plateScanValidators'

export default {
  name: 'MultiStamp',
  components: {
    'lb-plate': Plate,
    'lb-plate-scan': PlateScan,
    'lb-plate-summary': PlateSummary,
    'lb-loading-modal': LoadingModal,
    'lb-primer-panel-filter': PrimerPanelFilter,
    'lb-null-filter': NullFilter
  },
  props: {
    sequencescapeApi: { type: String, default: 'http://localhost:3000/api/v2' },
    purposeUuid: { type: String, required: true },
    targetUrl: { type: String, required: true },
    requestFilter: { type: String, required: true },
    transfersLayout: { type: String, required: true },
    targetRows: { type: String, required: true },
    targetColumns: { type: String, required: true },
    sourcePlates: { type: String, required: true },
    locationObj: { default: () => { return location }, type: [Object, Location] }
  },
  data () {
    return {
      // Cannot use computed functions as data is invoked before
      plates: builPlateObjs(Number.parseInt(this.sourcePlates)),
      devourApi: devourApi({ apiUrl: this.sequencescapeApi }, resources),
      requestsWithPlatesFiltered: [],
      loading: false,
      progressMessage: ''
    }
  },
  computed: {
    sourcePlateNumber() {
      return Number.parseInt(this.sourcePlates)
    },
    targetRowsNumber() {
      return Number.parseInt(this.targetRows)
    },
    targetColumnsNumber() {
      return Number.parseInt(this.targetColumns)
    },
    valid() {
      return this.unsuitablePlates.length === 0 // None of the plates are invalid
             && this.validTransfers.length > 0 // We have at least one transfer
             && this.overflownTransfers.length === 0 // No overflown transfers
             && this.duplicatedTransfers.length === 0 // No duplicated transfers
    },
    validPlates() {
      return this.plates.filter( plate => plate.state === 'valid' )
    },
    unsuitablePlates() {
      return this.plates.filter( plate => !(plate.state === 'valid' || plate.state === 'empty') )
    },
    requestsWithPlates() {
      return requestsFromPlates(this.validPlates).filter((requestWithPlate) =>
        requestIsActive(requestWithPlate.request))
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
    overflownTransfers() {
      return this.validTransfers.slice(this.targetRowsNumber * this.targetColumnsNumber)
    },
    apiTransfers() {
      const transfersArray = new Array(this.validTransfers.length)
      for (let i = 0; i < this.validTransfers.length; i++) {
        const transfer = this.validTransfers[i]
        transfersArray[i] = {
          source_plate: transfer.plateObj.plate.uuid,
          pool_index: transfer.plateObj.index + 1,
          source_asset: transfer.well.uuid,
          outer_request: transfer.request.uuid,
          new_target: { location: transfer.targetWell }
        }
      }
      return transfersArray
    },
    transfersError() {
      const errorMessages = []
      if (this.duplicatedTransfers.length > 0) {
        errorMessages.push('Duplicated transfers')
      }
      if (this.overflownTransfers.length > 0) {
        errorMessages.push('Overflown transfers')
      }
      return errorMessages.join(' and ')
    },
    targetWells() {
      let deb = this.apiTransfers.reduce((wells, transfer) => {
        wells[transfer.new_target.location] = { pool_index: transfer.pool_index }
        return wells
      }, {})
      return deb
    },
    requestsFilter() {
      return filterProps[this.requestFilter].requestsFilter
    },
    plateIncludes() {
      return filterProps[this.requestFilter].plateIncludes
    },
    plateFields() {
      return filterProps[this.requestFilter].plateFields
    },
    scanValidation() {
      const currPlates = this.plates.map(plateItem => plateItem.plate)
      return (index) => {
        return aggregate(
          checkSize(12, 8),
          checkDuplicates(currPlates, index),
          checkOverflows(this.overflownTransfers)
        )
      }
    }
  },
  methods: {
    updatePlate(index, data) {
      this.$set(this.plates, index - 1, {...data, index: index - 1 })
    },
    createPlate() {
      this.progressMessage = 'Creating plate...'
      this.loading = true
      let payload = { plate: {
        parent_uuid: this.validPlates[0].plate.uuid,
        purpose_uuid: this.purposeUuid,
        transfers: this.apiTransfers
      }}

      this.$axios({
        method: 'post',
        url:this.targetUrl,
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
