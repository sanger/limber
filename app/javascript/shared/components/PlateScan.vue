<template>
  <b-form-group
    :label="label"
    :label-cols="2"
    label-size="lg"
    :label-for="uid"
    :description="description"
    :state="formState"
    :invalid-feedback="feedback"
    :valid-feedback="feedback"
    :class="{ 'wait-plate': searching }"
  >
    <b-form-input
      :id="uid"
      v-model.trim="plateBarcode"
      type="text"
      :state="formState"
      size="lg"
      placeholder="Scan a plate"
      :disabled="scanDisabled"
      @change="lookupPlate"
    />
  </b-form-group>
</template>

<script>

import { checkSize, aggregate } from './plateScanValidators'

// Incrementing counter to ensure all instances of PlateScan
// have a unique id. Ensures labels correctly match up with
// fields
let uid = 0
const boolToString = { true: 'valid', false: 'invalid' }
/**
 * Provides a labelled text input box which will automatically search for a resource
 * from the Sequencescape V2 API by barcode. It provides:
 * - Customizable validation with user-feedback
 * - Emits plate objects, along with their validity.
 * - Customize include and fields options to meet downstream needs.
 */
export default {
  name: 'PlateScan',
  props: {
    api: {
      // A devour API object. eg. new devourClient(apiOptions)
      // In practice you probably want to use the helper in shared/devourApi
      type: Object, required: true
    },
    label: {
      // The label for the text field. Plate by default.
      type: String, default: 'Plate'
    },
    description: {
      // Optional description text which will be displayed below the input. Intended
      // To provide additional guidance to the user.
      type: String, required: false, default: null
    },
    includes: {
      // The include string used in the query. Used to list the associated records which will be returned.
      // See: https://github.com/twg/devour#relationships and https://jsonapi.org/format/#fetching-includes
      // Eg. wells.aliquots,purpose will return the plates wells, and purpose, and any aliquots in the wells.
      type: String, required: false, default: ''
    },
    fields: {
      // Used for sparse fieldsets. Allows you to specify which information to include for each record.
      // See: https://jsonapi.org/format/#fetching-sparse-fieldsets (Devour documentation is a bit limited here)
      // eg. { plates: 'name,labware_barcode,wells', wells: 'position' } will return the name and barcode of the plates,
      // and position of wells.
      // Gotchas:
      // - Resource types in keys should be plural.
      // - If you include associated records, the associated name should be included in the fields option to ensure
      //   devour can actually follow the association. (eg. plate should have the field wells if you also include wells)
      //
      default: () => { return { plates: 'labware_barcode,uuid,number_of_rows,number_of_columns' } },
      type: Object
    },
    validators: {
      // An array of validators. See plateScanValidators.js for examples and details
      type: Array, required: false, default: () => { return [checkSize(12, 8)] }
    },
    scanDisabled: {
      // Used to disable the scan field.
      type: Boolean, default: false
    },
    plateType: {
      // Used to specify the type of 'plate' to find by barcode e.g. plate, qcable.
      type: String, default: 'plate'
    }
  },
  data() {
    uid += 1
    return {
      plateBarcode: '', // The scanned barcode
      plate: null, // The plate object
      uid: `plate-scan-${uid}`, // Unique id to ensure label identifies the correct field
      apiActivity: { state: null, message: '' } // API status
    }
  },
  computed: {
    searching() { return this.apiActivity.state === 'searching' }, // The API is in progress
    state() { return this.validated.state }, // Overall state, eg. valid, invalid, empty
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
        return this.validatedPlate
      } else {
        return this.apiActivity
      }
    },
    feedback() {
      return this.validated.message
    },
    validatedPlate() {
      if (this.plate === null) {
        return { state: 'empty', message: '' }
      } else if (this.plate === undefined) {
        return { state: 'invalid', message: 'Could not find plate' }
      } else {
        const result = aggregate(this.validators, this.plate)
        return { state: boolToString[result.valid], message: result.message }
      }
    }
  },
  watch: {
    state() {
      this.$emit('change', { plate: this.plate, state: this.state })
    }
  },
  methods: {
    lookupPlate(_) {
      if (this.plateBarcode !== '') {
        this.apiActivity = { state: 'searching', message: 'Searching...' }
        this.findPlate()
          .then(this.apiSuccess)
          .catch(this.apiError)
      } else {
        this.plate = null
      }
    },
    async findPlate() {
      const plate = (
        await this.api.findAll(this.plateType, {
          include: this.includes,
          filter: { barcode: this.plateBarcode },
          fields: this.fields
        })
      )
      return plate.data[0]
    },
    apiSuccess(result) {
      this.plate = result
      this.apiActivity = { state: 'valid', message: 'Search complete' }
    },
    apiError(err) {
      if (!err) {
        this.apiActivity = { state: 'invalid', message: 'Unknown error' }
      } else if (err[0]) {
        const message = `${err[0].title}: ${err[0].detail}`
        this.apiActivity = { state: 'invalid', message }
      } else {
        this.apiActivity = { ...err, state: 'invalid' }
      }
    }
  }
}
</script>
