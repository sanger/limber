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
      v-model.trim="tubeBarcode"
      type="text"
      :state="formState"
      size="lg"
      placeholder="Scan a tube"
      :disabled="scanDisabled"
      @change="lookupTube"
    />
  </b-form-group>
</template>

<script>

import { aggregate } from './tubeScanValidators'

// Incrementing counter to ensure all instances of TubeScan
// have a unique id. Ensures labels correctly match up with
// fields
let uid = 0
const boolToString = { true: 'valid', false: 'invalid' }
/**
 * Provides a labelled text input box which will automatically search for a resource
 * from the Sequencescape V2 API by barcode. It provides:
 * - Customizable validation with user-feedback
 * - Emits tube objects, along with their validity.
 * - Customize include and fields options to meet downstream needs.
 */
export default {
  name: 'TubeScan',
  props: {
    api: {
      // A devour API object. eg. new devourClient(apiOptions)
      // In practice you probably want to use the helper in shared/devourApi
      type: Object, required: true
    },
    label: {
      // The label for the text field. Tube by default.
      type: String, default: 'Tube'
    },
    description: {
      // Optional description text which will be displayed below the input. Intended
      // To provide additional guidance to the user.
      type: String, required: false, default: null
    },
    includes: {
      // The include string used in the query. Used to list the associated records which will be returned.
      // See: https://github.com/twg/devour#relationships and https://jsonapi.org/format/#fetching-includes
      type: String, required: false, default: ''
    },
    fields: {
      // Used for sparse fieldsets. Allows you to specify which information to include for each record.
      // See: https://jsonapi.org/format/#fetching-sparse-fieldsets (Devour documentation is a bit limited here)
      // eg. { tubes: 'name,labware_barcode' } will return the name and barcode of the tubes.
      // Gotchas:
      // - Resource types in keys should be plural.
      // - If you include associated records, the associated name should be included in the fields option to ensure
      //   devour can actually follow the association.
      default: () => { return { tubes: 'labware_barcode,uuid,receptacle', receptacles: 'uuid' } },
      type: Object
    },
    validators: {
      // An array of validators. See tubeScanValidators.js for examples and details
      type: Array, required: false, default: () => { return [] }
    },
    scanDisabled: {
      // Used to disable the scan field.
      type: Boolean, default: false
    },
    tubeType: {
      // Used to specify the type of 'tube' to find by barcode
      type: String, default: 'tube'
    }
  },
  data() {
    uid += 1
    return {
      tubeBarcode: '', // The scanned barcode
      tube: null, // The tube object
      uid: `tube-scan-${uid}`, // Unique id to ensure label identifies the correct field
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
        return this.validatedTube
      } else {
        return this.apiActivity
      }
    },
    feedback() {
      return this.validated.message
    },
    validatedTube() {
      if (this.tube === null) {
        return { state: 'empty', message: '' }
      } else if (this.tube === undefined) {
        return { state: 'invalid', message: 'Could not find tube' }
      } else {
        const result = aggregate(this.validators, this.tube)
        return { state: boolToString[result.valid], message: result.message }
      }
    }
  },
  watch: {
    state() {
      this.$emit('change', { tube: this.tube, state: this.state })
    }
  },
  methods: {
    lookupTube(_) {
      if (this.tubeBarcode !== '') {
        this.apiActivity = { state: 'searching', message: 'Searching...' }
        this.findTube()
          .then(this.apiSuccess)
          .catch(this.apiError)
      } else {
        this.tube = null
      }
    },
    async findTube() {
      const tube = (
        await this.api.findAll(this.tubeType, {
          include: this.includes,
          filter: { barcode: this.tubeBarcode },
          fields: this.fields
        })
      )
      return tube.data[0]
    },
    apiSuccess(result) {
      this.tube = result
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
