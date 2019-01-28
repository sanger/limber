<template>
  <lb-page>
    <lb-loading-modal v-if="loading" :message="progressMessage"></lb-loading-modal>
    <lb-main-content>
      <b-card bg-variant="dark" text-variant="white">
        <lb-plate-summary v-for="plate in plates"
                         :state="plate.state"
                         :pool-index="plate.index + 1"
                         :key="plate.index"
                         :plate="plate.plate"></lb-plate-summary>
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
                         :includes="{wells: {'requests_as_source': 'primer_panel', aliquots: {'request': 'primer_panel'}}}"
                         :selects="{ plates: [ 'labware_barcode', 'wells', 'uuid', 'number_of_rows', 'number_of_columns' ],
                                     requests: [ 'primer_panel', 'uuid'],
                                     wells: ['position', 'requests_as_source', 'aliquots', 'uuid'],
                                     aliquots: ['request'] }"
                         v-on:change="updatePlate(i, $event)"></lb-plate-scan>
        </b-form-group>
        <b-form-group label="Select a primer panel to process">
          <b-form-radio-group v-model="primerPanel"
                       :options="primerPanels"
                       size="lg"></b-form-radio-group>
        </b-form-group>
        <b-button :disabled="!valid" variant="success" v-on:click="createPlate()">Create</b-button>
      </b-card>
    </lb-sidebar>
  </lb-page>
</template>

<script>

  import Plate from 'shared/components/Plate'
  import PlateSummary from './PlateSummary'
  import PlateScan from 'shared/components/PlateScan'
  import LoadingModal from 'shared/components/LoadingModal'
  import devourApi from 'shared/devourApi'
  import resources from 'shared/resources'
  import buildArray from 'shared/buildArray'
  import { wellNameToCoordinate, wellCoordinateToName, requestsForWell } from 'shared/wellHelpers'

  export default {
    name: 'QuadStamp',
    data () {
      let plateArray = buildArray(this.sourcePlateNumber, (iteration) => { return { state: 'empty', plate: null, index: iteration } })

      return {
        devourApi: devourApi({ apiUrl: this.sequencescapeApi }, resources),
        plates: plateArray,
        primerPanel: null,
        loading: false,
        progressMessage: ''
      }
    },
    props: {
      sequencescapeApi: { type: String, default: 'http://localhost:3000/api/v2' },
      purposeUuid: { type: String, required: true },
      targetUrl: { type: String, required: true },
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
        this.$set(this.plates, index - 1, {...data, index: index -1 })
      },
      requestFor(well) {
        return requestsForWell(well).find((request) => {
            return request.primer_panel && request.primer_panel.name === this.primerPanel
        })
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
      transfers() {
        let transferArray = []
        this.validPlates.forEach((plateState) => {
          let { plate, index } = plateState
          plate.wells.forEach((well) => {
            let request = this.requestFor(well)
            if (request === undefined) { return }
            let targetWell = this.targetFor(index, well.position.name)
            transferArray.push({
              source_plate: plate.uuid,
              pool_index: index + 1,
              source_asset: well.uuid,
              outer_request: request.uuid,
              new_target: { location: targetWell } }
            )
          })
        })
        return transferArray
      },
      primerPanels() { // Returns the mutual primer panels
        let primerPanels = null
        this.validPlates.forEach((plateState) => {
          let { plate, index } = plateState
          plate.wells.forEach((well) => {
            let wellRequests = requestsForWell(well).filter(request => request.primerPanel)
            if (wellRequests.length === 0) { return } // If we have no requests, skip to the next well
            let wellPrimerPanels = wellRequests.map(request => request.primerPanel.name )
            if (primerPanels === null) {
              primerPanels = wellPrimerPanels
            } else {
              primerPanels = primerPanels.filter(panel => wellPrimerPanels.includes(panel) )
            }
          })
        })
        return primerPanels || []
      },
      targetWells() {
        let deb = this.transfers.reduce((wells, transfer) =>{
          wells[transfer.new_target.location] = { pool_index: transfer.pool_index }
          return wells
        }, {})
        return deb
      }
    },
    components: {
      'lb-plate': Plate,
      'lb-plate-scan': PlateScan,
      'lb-plate-summary': PlateSummary,
      'lb-loading-modal': LoadingModal
    }
  }
</script>
