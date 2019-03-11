<template>
  <b-form-group
    horizontal
    :label="label"
    :label-cols="2"
    label-size="lg"
    :label-for="uid"
    :description="description"
    :state="state"
    :invalid-feedback="invalidFeedback"
    :valid-feedback="validFeedback"
    :class="{ 'wait-plate': searching }"
  >
    <b-form-input
      :id="uid"
      v-model.trim="plateBarcode"
      type="text"
      :state="state"
      size="lg"
      placeholder="Scan a plate"
      @change="lookupPlate"
    />
  </b-form-group>
</template>

<script>

// Incrementing counter to ensure all instances of PlateScan
// have a unique id. Ensures labels correctly match up with
// fields
let uid = 0

export default {
  name: 'PlateScan',
  props: {
    api: { required: false },
    label: { type: String, default: 'Plate'},
    description: { type: String },
    includes: { default: () => { return '' } },
    fields: { default: () => { return { plates: 'labware_barcode,uuid,number_of_rows,number_of_columns' } } },
    plateCols: { type: Number, default: 12 },
    plateRows: { type: Number, default: 8 }
  },
  data() {
    uid += 1
    return {
      plateBarcode: '',
      plate: null,
      state: 'empty',
      invalidFeedback: '',
      validFeedback: '',
      uid: `plate-scan-${uid}`
    }
  },
  computed: {
    searching: function() { return this.state === 'searching' }
  },
  watch: {
    state: function() {
      this.$emit('change', { plate: this.plate, state: this.state })
    }
  },
  methods: {
    lookupPlate: function (_) {
      if (this.plateBarcode !== '') {
        this.findPlate()
          .then(this.validatePlate)
          .catch(this.apiError)
      } else {
        this.plate = null
        this.state = 'empty'
      }
    },
    async findPlate () {
      this.state = 'searching'
      const plate = (
        await this.api.findAll('plate', {
          include: this.includes,
          filter: { barcode: this.plateBarcode },
          fields: this.fields
        })
      )
      return plate.data[0]
    },
    validatePlate: function (plate) {
      if (plate === undefined) {
        this.plate = null
        this.badState({ message: 'Could not find plate' })
      } else {
        this.plate = plate
        if (this.incorrectSize(plate)) {
          this.badState({ message: `The plate should be ${this.plateCols}×${this.plateRows} wells in size` })
        } else {
          this.goodState({ message: 'Great!' })
        }
      }
    },
    incorrectSize: function(plate) {
      return plate.number_of_columns !== this.plateCols ||
               plate.number_of_rows !== this.plateRows
    },
    apiError: function(err) {
      if (!err) {
        this.badState({message: 'Unknown error'})
      } else if (err[0]) {
        const message = `${err[0].title}: ${err[0].detail}`
        this.badState({ message })
      } else {
        this.badState(err)
      }
    },
    badState: function(err) {
      this.state = 'invalid'
      this.invalidFeedback = err.message || 'Unknown error'
    },
    goodState: function(msg) {
      this.state = 'valid'
      this.validFeedback = 'Great!'
    }
  }
}
</script>

