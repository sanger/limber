<template>
  <lb-page>
    <lb-loading-modal v-if="loading" :message="progressMessage" />
    <lb-main-content>
      <b-card bg-variant="dark" text-variant="white" :header="header" header-tag="h3">
        <lb-plate
          caption="Layout of the new plate"
          :rows="targetRowsNumber"
          :columns="targetColumnsNumber"
          :wells="targetWells"
        />
        <hr />
        <lb-tube-array-summary :tubes="tubes" />
      </b-card>
    </lb-main-content>
    <lb-sidebar>
      <b-card header="Scan tubes" header-tag="h3">
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
            :colour-index="colourIndex(i - 1)"
            :labware-type="'tube'"
            :valid-message="''"
            @change="updateTube(i, $event)"
          />
        </b-form-group>
        <b-alert :model-value="transfersError !== ''" variant="danger">
          {{ transfersError }}
        </b-alert>
        <component
          :is="transfersCreatorComponent"
          :valid-transfers="validTransfers"
          @update:model-value="transfersCreatorObj = $event"
        />
        <hr />
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
  checkState,
  checkAcceptablePurposes,
} from '@/javascript/shared/components/tubeScanValidators.js'
import devourApi from '@/javascript/shared/devourApi.js'
import { handleFailedRequest } from '@/javascript/shared/requestHelpers.js'
import resources from '@/javascript/shared/resources.js'
import { transferTubesToPlateCreator } from '@/javascript/shared/transfersCreators.js'
import { transfersForTubes } from '@/javascript/shared/transfersLayouts.js'
import { buildTubeObjs } from '@/javascript/shared/tubeHelpers.js'
import { findUniqueIndex, indexToName } from '@/javascript/shared/wellHelpers.js'
import MultiStampTubesTransfers from './MultiStampTubesTransfers.vue'
import TubeArraySummary from './TubeArraySummary.vue'
import filterProps from './filterProps.js'
import transfersCreatorsComponentsMap from './transfersCreatorsComponentsMap.js'

// Multistamp tubes is used in Cardinal and scRNA pipelines to record the transfers of samples from
// tubes to a plate.
//
// In the Lab there are three steps to this process:
// 1. The Lab user arrays the tubes in an (untracked) tube rack. This component is responsible for tracking that
// arraying of tubes into the rack, by scanning each into a position. Limber LIMS records that arrangement
// of tubes as transfers into the wells of a new child plate (we do not model the rack).
// 2. The Lab user can then download from LIMS a printed version of that arrangement of tubes to paper, and print
// a label for the child plate.
// 3. The Lab user takes the paper printout, the rack of tubes, and the labeled child plate to the fume hood and
// manually transfers the samples from the tubes to the plate according to the plan. The printout is their
// checklist. Once done they click the Manual Transfer button in LIMS to action the transfers of samples into
// the child plate.

export default {
  name: 'MultiStampTubes',
  components: {
    'lb-plate': Plate,
    'lb-tube-array-summary': TubeArraySummary,
    'lb-labware-scan': LabwareScan,
    'lb-loading-modal': LoadingModal,
    'lb-multi-stamp-tubes-transfers': MultiStampTubesTransfers,
  },
  props: {
    // Sequencescape API V2 URL
    sequencescapeApi: { type: String, default: 'http://localhost:3000/api/v2' },

    // Sequencescape API V2 API key
    sequencescapeApiKey: { type: String, default: 'development' },

    // Limber plate purpose UUID
    purposeUuid: { type: String, required: true },

    // Limber plate purpose name
    purposeName: { type: String, required: true },

    // Limber parent purpose name
    parentPurposeName: { type: String, required: true },

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
    locationObj: {
      default: () => {
        return location
      },
      type: [Object, Location],
    },

    // Should tube duplication validation be included or skipped
    // Also referenced as allow-tube-duplicates and allow_tube_duplicates
    allowTubeDuplicates: { type: String, required: true },

    // Should tubes be required to be in passed state
    // Also referenced as require-tube-passed and require_tube_passed
    requireTubePassed: { type: String, required: true },

    // A acceptable list of purpose names that can be scanned
    // If left empty all purposes are acceptable
    // Also referenced as data-acceptable-purposes and data_acceptable_purposes
    // See computed method acceptablePurposesArray for conversion to array.
    acceptablePurposes: { type: String, required: false, default: '[]' },
  },
  data() {
    return {
      // Array containing objects with scanned tubes, their states and the
      // index of the form input in which they were scanned.
      // Note: Cannot use computed functions as data is invoked before
      tubes: buildTubeObjs(Number.parseInt(this.sourceTubes)),

      // Devour API object to deserialise assets from sequencescape API.
      // (See ../../shared/resources.js for details)
      devourApi: devourApi({ apiUrl: this.sequencescapeApi }, resources, this.sequencescapeApiKey),

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
    // Returns the header for the page
    header() {
      return `Sample Arraying: ${this.parentPurposeName} → ${this.purposeName}`
    },
    sourceTubeNumber() {
      return Number.parseInt(this.sourceTubes)
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
    // Returns a boolean indicating whether the provided tubes are valid.
    // Used to enable and disable the 'Create' button.
    valid() {
      return (
        this.unsuitableTubes.length === 0 && // None of the tubes are invalid
        this.validTransfers.length > 0 && // We have at least one transfer
        this.transfersCreatorObj.isValid
      )
    },
    // Returns an array of tubes that are in a 'valid' state.
    validTubes() {
      return this.tubes.filter((tube) => tube.state === 'valid')
    },
    // Returns an array of tubes that are not in a 'valid' or 'empty' state.
    unsuitableTubes() {
      return this.tubes.filter((tube) => !(tube.state === 'valid' || tube.state === 'empty'))
    },
    transfers() {
      return transfersForTubes(this.validTubes)
    },
    //  validTransfers returns an array with the following structure:
    //
    //  [
    //    { tubeObj: { index: 0, tube: {...} }, targetWell: 'A1' },
    //    { tubeObj: { index: 1, tube: {...} }, targetWell: 'A2' },
    //    ...etc...
    //  ]
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
    // map of well positions tube metadata, eg:
    // {
    //   "A1": {
    //     colour_index: 1,
    //     human_barcode: "DN123456"
    //   },
    //   "B4": {
    //     colour_index: 2,
    //     human_barcode: "DN123457"
    //   },
    //   ...
    // }
    targetWells() {
      return this.validTransfers.reduce((acc, transfer) => {
        acc[transfer.targetWell] = {
          colour_index: this.colourIndex(transfer.tubeObj.index),
          human_barcode: transfer.tubeObj.tube.labware_barcode.human_barcode,
        }
        return acc
      }, {})
    },
    tubeIncludes() {
      return filterProps.tubeIncludes
    },
    tubeFields() {
      return filterProps.tubeFields
    },
    scanValidation() {
      const validators = []

      // If any acceptablePurposes specified then ensure we validate against them
      if (this.acceptablePurposesArray.length) validators.push(checkAcceptablePurposes(this.acceptablePurposesArray))

      if (this.requireTubePassed === 'true') validators.push(checkState(['passed']))

      if (this.allowTubeDuplicates === 'true') return validators

      // add duplicate check to validators
      const currTubes = this.tubes.map((tubeItem) => tubeItem.labware)
      validators.push(checkDuplicates(currTubes))

      return validators
    },
  },
  methods: {
    // Given a 0-based well index, return the well name.
    // e.g. 0 -> A1, 1 -> A2, etc.
    wellIndexToName(index) {
      return indexToName(index, this.targetRowsNumber)
    },
    // Determines the colour of the tube based on its barcode,
    // where tubes with the same barcode have the same colour.
    // Returns an integer that is used elsewhere to build the colour class name (see colours.css).
    // Returns -1 if the tube is not valid.
    colourIndex(tubeIndex) {
      let colour_index = -1

      const tube = this.tubes[tubeIndex]
      if (!tube || tube.state !== 'valid') return colour_index

      const tube_machine_barcode = tube.labware.labware_barcode.machine_barcode
      const tube_machine_barcodes = this.tubes
        .filter((tube) => tube.state === 'valid')
        .map((tube) => tube.labware.labware_barcode.machine_barcode)

      const barcode_index = findUniqueIndex(tube_machine_barcodes, tube_machine_barcode)
      if (barcode_index !== -1) colour_index = barcode_index + 1

      return colour_index
    },
    /**
     * The entry point for updating tubes attached to the plate.
     * Called when a tube is scanned into a well.
     *
     * @param {Number} index - The (1-based) index of the tube in the tubes array.
     * @param {Object} data - The tube object returned from the scan, which includes:
     *   - labware: Contains details about the labware, such as id, uuid, and barcode details.
     *   - state: The "scanned" state of the tube, e.g., "valid".
     *   @example {
     *     labware: {
     *       id: "47",
     *       uuid: "1234-5678-91011",
     *       labware_barcode: {
     *         ean13_barcode: "3980000035714",
     *         human_barcode: "NT35G",
     *         machine_barcode: "3980000035714"
     *       },
     *       links: {...},
     *       receptacle: {...},
     *       type: "tubes",
     *       state: "passed"
     *     },
     *     state: "valid"
     *   }
     */
    updateTube(index, data) {
      this.tubes[index - 1] = { ...data, index: index - 1 }
    },
    apiTransfers() {
      // what we want to transfer when creating the plate
      return transferTubesToPlateCreator(this.validTransfers, this.transfersCreatorObj.extraParams)
    },
    createPlate() {
      this.progressMessage = 'Creating plate...'
      this.loading = true
      let payload = {
        plate: {
          parent_uuid: this.validTubes[0].labware.uuid, // TODO: this is just one tube of 96 and assumes A1 is filled, it may not be
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
