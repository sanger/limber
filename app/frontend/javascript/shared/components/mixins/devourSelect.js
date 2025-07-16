import { validateError } from '@/javascript/shared/devourApiValidators.js'

const boolToString = { true: 'valid', false: 'invalid' }

/**
 * Performs a find via the Devour API
 * The results should include all matching elements for the supplied includes,
 * fields, and filter.
 * Validation is optional.
 * Nothing is rendered.
 * It provides:
 * - a Devour api find framework
 */
export default {
  name: 'DevourSelect',
  props: {
    api: {
      // A devour API object. eg. new devourClient(apiOptions)
      // In practice you probably want to use the helper in shared/devourApi
      type: Object,
      required: true,
    },
    resourceName: {
      // Used to determine the database resource name to search on
      // e.g. 'plate'
      // N.B. devour seems to pluralize this so 'plates' also works.
      type: String,
      required: true,
      default: '',
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
      // eg. { plates: 'name,labware_barcode,wells', wells: 'position' } will return the name and barcode of the plates,
      // and position of wells.
      // Gotchas:
      // - Resource types in keys should be plural.
      // - If you include associated records, the associated name should be included in the fields option to ensure
      //   devour can actually follow the association. (eg. plate should have the field wells if you also include wells)
      //
      type: Object,
      required: false,
      default: () => {
        return {}
      },
    },
    filter: {
      // Used to filter the find results on a specific field value
      // e.g. { barcode: this.plateBarcode }
      // e.g. { uuid: this.assetUuid }
      // e.g. { page: { number: 2 }}
      type: Object,
      required: false,
      default: () => {
        return {}
      },
    },
    validation: {
      // A validation function. see plateScanValidators.js for examples and details
      type: Function,
      required: false,
      default: () => {
        return { valid: true, message: '' }
      },
    },
  },
  emits: ['change'],
  data() {
    return {
      results: null, // holds the query results
      apiActivity: { state: null, message: '' }, // API status
    }
  },
  watch: {
    state: function () {
      if (this.state && this.state !== 'searching') {
        this.$emit('change', {
          state: this.state,
          results: this.reformattedResults,
        })
      }
    },
  },
  computed: {
    state() {
      return this.validated.state
    }, // Overall state, eg. valid, invalid, empty
    validated() {
      if (this.apiActivity.state === 'valid') {
        return this.validatedResults
      } else {
        return this.apiActivity
      }
    },
    feedback() {
      return this.validated.message
    },
    validatedResults() {
      if (this.results === null) {
        return { state: 'empty', message: '' }
      } else if (this.results === undefined) {
        return {
          state: 'invalid',
          message: `Could not find ${this.resourceName}`,
        }
      } else {
        const validationResult = this.validation(this.results)
        return {
          state: boolToString[validationResult.valid],
          message: validationResult.message,
        }
      }
    },
    // override this if you wish to modify the results before emitting
    reformattedResults() {
      return this.results
    },
  },
  methods: {
    performLookup(_) {
      if (this.resourceName !== '') {
        this.apiActivity = { state: 'searching', message: 'Searching...' }
        this.performFind().then(this.apiSuccess).catch(this.apiError)
      } else {
        this.results = null
      }
    },
    // Override this method when you need different behaviour
    async performFind() {
      // returns a promise that can later be caught should the request fail
      return await this.api
        .findAll(this.resourceName, {
          include: this.includes,
          filter: this.filter,
          fields: this.fields,
        })
        .then((response) => {
          return response.data
        })
    },
    apiSuccess(results) {
      this.results = results
      this.apiActivity = { state: 'valid', message: 'Search complete' }
    },
    apiError(response) {
      this.apiActivity = validateError(response)
    },
  },
  render() {
    return ''
  },
}
