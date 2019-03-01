<template>
  <lb-page>
    <lb-loading-modal v-if="loading" :message="progressMessage"></lb-loading-modal>
    <lb-main-content>
      <b-card bg-variant="dark" text-variant="white">
        <lb-plate-summary v-for="plate in plates"
                         :state="plate.state"
                         :pool-index="plate.index + 1"
                         :key="plate.index"
                         :plate="plate.plate">
        </lb-plate-summary>
        <lb-plate caption="New Plate" :rows="targetRows" :columns="targetColumns" :wells="targetWells"></lb-plate>
      </b-card>
    </lb-main-content>
    <lb-sidebar>
      <b-card header="Add plates" header-tag="h3">
        <b-form-group label="Scan in the plates you wish to use">
          <lb-plate-scan v-for="i in sourcePlateNumber"
                         :api="devourApi"
                         :label="'Plate ' + i"
                         :key="i"
                         :includes="plateIncludes"
                         :fields="plateFields"
                         @change="updatePlate(i, $event)">
          </lb-plate-scan>
        </b-form-group>
        <component :is="requestsFilter"
                   :requestsWithPlates="requestsWithPlates"
                   @change="requestsWithPlatesFiltered = $event">
        </component>
        <b-button :disabled="!valid" variant="success" @click="createPlate()">Create</b-button>
      </b-card>
    </lb-sidebar>
  </lb-page>
</template>

<script>
  import PlateSummary from './PlateSummary'
  import PrimerPanelFilter from './PrimerPanelFilter'
  import NullFilter from './NullFilter'
  import Plate from 'shared/components/Plate'
  import PlateScan from 'shared/components/PlateScan'
  import LoadingModal from 'shared/components/LoadingModal'
  import devourApi from 'shared/devourApi'
  import resources from 'shared/resources'
  import builPlateObjs from 'shared/plateHelpers'
  import requestIsActive from 'shared/requestHelpers'
  import { wellNameToCoordinate, wellCoordinateToName, requestsForWell } from 'shared/wellHelpers'

  export default {
    name: 'QuadStamp',
    data () {
      return {
        plates: builPlateObjs(this.sourcePlateNumber),
        devourApi: devourApi({ apiUrl: this.sequencescapeApi }, resources),
        requestsWithPlatesFiltered: [],
        loading: false,
        progressMessage: ''
      }
    },
    props: {
      sequencescapeApi: { type: String, default: 'http://localhost:3000/api/v2' },
      purposeUuid: { type: String, required: true },
      targetUrl: { type: String, required: true },
      requestFilters: { type: String, required: true },
      targetRows: { type: Number, default: 16 },
      targetColumns: { type: Number, default: 24 },
      sourcePlateNumber: { type: Number, default: 4 },
      // Defaults assumes column orientated stamping.
      rowOffset: { type: Array, default: () =>{ return [0,1,0,1] } },
      colOffset: { type: Array, default: () =>{ return [0,0,1,1] } },
      locationObj: { default: () => { return location } }
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
        this.progressMessage = "Creating plate..."
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
      requestsFromPlates(plateObjs) {
        let requestsArray = []
        plateObjs.forEach((plateObj) => {
          plateObj.plate.wells.forEach((well) => {
            requestsForWell(well).forEach((request) => {
              if (requestIsActive(request)) {
                requestsArray.push({
                  request: request,
                  well: well,
                  plateObj: plateObj
                })
              }
            })
          })
        })
        return requestsArray
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
        return this.requestsFromPlates(this.validPlates)
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
        if (this.requestFilters === 'primer-panel') {
          return 'lb-primer-panel-filter'
        }
        else {
          return 'lb-null-filter'
        }
      },
      plateIncludes() {
        if (this.requestFilters === 'primer-panel') {
          return 'wells,wells.requests_as_source,wells.requests_as_source.primer_panel,wells.aliquots.request.primer_panel'
        }
        else {
          return 'wells,wells.requests_as_source,wells.aliquots'
        }
      },
      plateFields() {
        if (this.requestFilters === 'primer-panel') {
          return { plates: 'labware_barcode,wells,uuid,number_of_rows,number_of_columns',
                   requests: 'primer_panel,uuid',
                   wells: 'position,requests_as_source,aliquots,uuid',
                   aliquots: 'request' }
        }
        else {
          return { plates: 'labware_barcode,wells,uuid,number_of_rows,number_of_columns',
                   requests: 'uuid',
                   wells: 'position,requests_as_source,aliquots,uuid',
                   aliquots: 'request' }
        }
      }
    },
    components: {
      'lb-plate': Plate,
      'lb-plate-scan': PlateScan,
      'lb-plate-summary': PlateSummary,
      'lb-loading-modal': LoadingModal,
      'lb-primer-panel-filter': PrimerPanelFilter,
      'lb-null-filter': NullFilter
    }
  }
</script>
