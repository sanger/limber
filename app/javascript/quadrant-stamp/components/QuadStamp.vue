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
          :rows="targetRows"
          :columns="targetColumns"
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
import { wellNameToCoordinate, wellCoordinateToName } from 'shared/wellHelpers'
import { checkSize, checkDuplicates, aggregate } from 'shared/components/plateScanValidators'

export default {
  name: 'QuadStamp',
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
    targetRows: { type: Number, default: 16 },
    targetColumns: { type: Number, default: 24 },
    sourcePlateNumber: { type: Number, default: 4 },
    // Defaults assumes column orientated stamping.
    rowOffset: { type: Array, default: () => { return [0,1,0,1] } },
    colOffset: { type: Array, default: () => { return [0,0,1,1] } },
    locationObj: { default: () => { return location }, type: [Object, Location] }
  },
  data () {
    return {
      plates: builPlateObjs(this.sourcePlateNumber),
      devourApi: devourApi({ apiUrl: this.sequencescapeApi }, resources),
      requestsWithPlatesFiltered: [],
      loading: false,
      progressMessage: ''
    }
  },
  computed: {
    valid() {
      return this.unsuitablePlates.length === 0 && // None of the plates are invalid
               this.transfers.length >= 1 // We have at least one transfer
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
      return this.transfersFromRequests(this.requestsWithPlatesFiltered)
    },
    targetWells() {
      let deb = this.transfers.reduce((wells, transfer) => {
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
        return aggregate(checkSize(12,8), checkDuplicates(currPlates, index))
      }
    }
  },
  methods: {
    updatePlate(index, data) {
      this.$set(this.plates, index - 1, {...data, index: index - 1 })
    },
    targetFor(quadrant, wellName) {
      let wellCoordinate = wellNameToCoordinate(wellName)
      let destinationRow = wellCoordinate[1] * 2 + this.rowOffset[quadrant]
      let destinationColumn = wellCoordinate[0] * 2 + this.colOffset[quadrant]
      return wellCoordinateToName([destinationColumn, destinationRow])
    },
    createPlate() {
      this.progressMessage = 'Creating plate...'
      this.loading = true
      let payload = { plate: {
        parent_uuid: this.validPlates[0].plate.uuid,
        purpose_uuid: this.purposeUuid,
        transfers: this.transfers
      }}
      this.$axios({
        method: 'post',
        url:this.targetUrl,
        headers: {'X-Requested-With': 'XMLHttpRequest'},
        data: payload
      }).then((response)=>{
        // Ajax responses automatically follow redirects, which
        // would result in us receiving the full HTML for the child
        // plate here, which we'd then need to inject into the
        // page, and update the history. Instead we don't redirect
        // application/json requests, and redirect the user ourselves.
        this.progressMessage = response.data.message
        this.locationObj.href = response.data.redirect
      }).catch((error)=>{
        // Something has gone wrong
        console.log(error)
        this.loading = false
      })
    },
    transfersFromRequests(requestsWithPlates) {
      let transfersArray = []
      requestsWithPlates.forEach((requestWithPlate) => {
        let { request, well, plateObj } = requestWithPlate
        if (request === undefined) { return }
        let targetWell = this.targetFor(plateObj.index, well.position.name)
        transfersArray.push({
          source_plate: plateObj.plate.uuid,
          pool_index: plateObj.index + 1,
          source_asset: well.uuid,
          outer_request: request.uuid,
          new_target: { location: targetWell } }
        )
      })
      return transfersArray
    }
  }
}
</script>
