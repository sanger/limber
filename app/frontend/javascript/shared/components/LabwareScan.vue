<template>
  <b-row>
    <b-col v-if="showWellIndicator" cols="1">
      <div :class="['pool-colours']">
        <div :id="'well_index_' + colourIndex" class="well">
          <span :class="['aliquot', colourClass]" />
        </div>
      </div>
    </b-col>
    <b-col class="mb-2">
      <b-form-group
        :label="label"
        :label-cols="labelColumnSpan"
        label-size="lg"
        :label-for="uid"
        :description="description"
        :state="formState"
        :invalid-feedback="feedback"
        :valid-feedback="feedback"
        :class="{ 'wait-labware': searching }"
      >
        <b-form-input
          :id="uid"
          ref="scan"
          v-model.trim="labwareBarcode"
          type="text"
          :state="formState"
          size="lg"
          :placeholder="'Scan ' + labwareType"
          :disabled="scanDisabled"
          @change="lookupLabware"
        />
      </b-form-group>
    </b-col>
  </b-row>
</template>

<script>
import { checkSize } from './plateScanValidators.js'
import { aggregate } from './scanValidators.js'
import { validateError } from '@/javascript/shared/devourApiValidators.js'

// Incrementing counter to ensure all instances of LabwareScan
// have a unique id. Ensures labels correctly match up with
// fields
let uid = 0
const boolToString = { true: 'valid', false: 'invalid' }
/**
 * Provides a labelled text input box which will automatically search for a resource
 * from the Sequencescape V2 API by barcode. It provides:
 * - Customizable validation with user-feedback
 * - Emits plate or tube objects, along with their validity.
 * - Customize include and fields options to meet downstream needs.
 */
export default {
  name: 'LabwareScan',
  props: {
    api: {
      // A devour API object. eg. new devourClient(apiOptions)
      // In practice you probably want to use the helper in shared/devourApi
      type: Object,
      required: true,
    },
    label: {
      // The label for the text field.
      type: String,
      default: 'Plate',
    },
    labelColumnSpan: {
      // The number of columns for the label to span
      type: Number,
      default: 2,
    },
    description: {
      // Optional description text which will be displayed below the input. Intended
      // To provide additional guidance to the user.
      type: String,
      required: false,
      default: null,
    },
    includes: {
      // The include string used in the query. Used to list the associated records which will be returned.
      // See: https://github.com/twg/devour#relationships and https://jsonapi.org/format/#fetching-includes
      // Eg. wells.aliquots,purpose will return the plates wells, and purpose, and any aliquots in the wells.
      type: String,
      required: false,
      default: '',
    },
    fields: {
      // Used for sparse fieldsets. Allows you to specify which information to include for each record.
      // See: https://jsonapi.org/format/#fetching-sparse-fieldsets (Devour documentation is a bit limited here)
      // eg.1 { plates: 'name,labware_barcode,wells', wells: 'position' } will return the name and barcode of the plates,
      // and position of wells.
      // eg.2 { tubes: 'name,labware_barcode' } will return the name and barcode of the tubes.
      // Gotchas:
      // - Resource types in keys should be plural.
      // - If you include associated records, the associated name should be included in the fields option to ensure
      //   devour can actually follow the association. (eg. plate should have the field wells if you also include wells)
      // defaults are set based on labwareType, in method 'fieldsToRetrieve'
      type: Object,
      default: null,
    },
    validators: {
      // An array of validators. See plateScanValidators.js and tubeScanValidators.js for options and details
      // and ValidatePairedTubes.vue for an usage example.
      // Defaults are set based on labwareType, in method 'computedValidators'.
      type: Array,
      required: false,
      default: null,
    },
    scanDisabled: {
      // Used to disable the scan field.
      type: Boolean,
      default: false,
    },
    labwareType: {
      type: String,
      default: 'plate',
    },
    colourIndex: {
      type: Number,
      default: null,
    },
    validMessage: {
      type: String,
      default: 'Great!',
    },
  },
  emits: ['change'],
  data() {
    uid += 1
    return {
      labwareBarcode: '', // The scanned barcode
      labware: null, // The labware object
      uid: `labware-scan-${uid}`, // Unique id to ensure label identifies the correct field
      apiActivity: { state: null, message: '' }, // API status
    }
  },
  computed: {
    showWellIndicator() {
      return this.labwareType == 'tube' && this.colourIndex !== null
    },
    searching() {
      return this.apiActivity.state === 'searching'
    }, // The API is in progress
    state() {
      return this.validated.state
    }, // Overall state, eg. valid, invalid, empty
    formState() {
      switch (this.state) {
        case 'valid':
          return true
        case 'invalid':
          return false
        default:
          return null
      }
    },
    validated() {
      if (this.apiActivity.state === 'valid') {
        return this.validatedLabware
      } else {
        return this.apiActivity
      }
    },
    feedback() {
      if (this.validated.state === 'valid') {
        return this.validMessage
      }
      return this.validated.message
    },
    validatedLabware() {
      if (this.labware === null) {
        return { state: 'empty', message: '' }
      } else if (this.labware === undefined) {
        return {
          state: 'invalid',
          message: `Could not find ${this.labwareType}`,
        }
      } else {
        const result = aggregate(this.computedValidators, this.labware)
        return { state: boolToString[result.valid], message: result.message }
      }
    },
    computedValidators() {
      if (this.validators) {
        return this.validators
      }

      if (this.labwareType == 'tube') {
        return []
      } else {
        return [checkSize(12, 8)]
      }
    },
    colourClass() {
      return `colour-${this.colourIndex}`
    },
  },
  watch: {
    state() {
      let message
      if (this.labwareType == 'tube') {
        message = { labware: this.labware, state: this.state }
      } else {
        message = { plate: this.labware, state: this.state }
      }
      this.$emit('change', message)
    },
  },
  methods: {
    lookupLabware(_) {
      if (this.labwareBarcode !== '') {
        this.apiActivity = { state: 'searching', message: 'Searching...' }
        this.findLabware().then(this.apiSuccess).catch(this.apiError)
      } else {
        this.labware = null
      }
    },
    async findLabware() {
      // returns a promise that can later be caught should the request fail
      return await this.api
        .findAll(this.labwareType, {
          include: this.includes,
          filter: { barcode: this.labwareBarcode },
          fields: this.fieldsToRetrieve(),
        })
        .then((response) => {
          return response.data[0]
        })
    },
    fieldsToRetrieve() {
      if (this.fields) {
        return this.fields
      }

      if (this.labwareType == 'tube') {
        return {
          tubes: 'labware_barcode,uuid,receptacle,state,purpose',
          receptacles: 'uuid',
        }
      } else {
        return {
          plates: 'labware_barcode,uuid,number_of_rows,number_of_columns',
        }
      }
    },
    apiSuccess(result) {
      this.labware = result
      this.apiActivity = { state: 'valid', message: 'Search complete' }
    },
    apiError(response) {
      this.apiActivity = validateError(response)
    },
    focus() {
      this.$refs.scan.$el.focus()
    },
  },
}
</script>

<style scoped lang="scss">
.well {
  height: 38px;
  width: 30px;
  margin-top: 10px;
  text-align: center;
  overflow: hidden;
  display: inline-block;
  vertical-align: middle;

  .aliquot {
    width: 26px;
    height: 26px;
    margin-top: 2px;
    text-align: center;
    display: inline-block;
    border: 2px #343a40 solid;
    border-radius: 7px;
  }

  .colour--1 {
    // --1 is 'dash minus one': used to indicate an empty well
    background-color: #e9ecef;
  }
}
</style>
