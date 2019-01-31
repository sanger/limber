<template>
  <b-form-group horizontal
                :label="label"
                :label-cols="2"
                label-size="lg"
                label-for="plateScan"
                :description="description"
                :state="state"
                :invalid-feedback="invalidFeedback"
                :valid-feedback="validFeedback"
                v-bind:class="{ 'wait-plate': searching }">
    <b-form-input id="plateScan"
                  type="text"
                  v-model.trim="plateBarcode"
                  :state="state"
                  size="lg"
                  placeholder="Scan a plate"
                  v-on:change="lookupPlate"
                  >
    </b-form-input>
  </b-form-group>
</template>

<script>
  export default {
    name: 'PlateScan',
    data() {
      return {
        plateBarcode: '',
        plate: null,
        state: 'empty',
        invalidFeedback: '',
        validFeedback: ''
      }
    },
    props: {
      plateApi: { required: false },
      api: { required: false },
      label: { type: String, default: 'Plate'},
      description: { type: String },
      plateType: { type: String, default: 'plate' },
      includes: { default: () => { return [] } },
      selects: { default: () => { return { plates: [ 'labware_barcode', 'uuid', 'number_of_rows', 'number_of_columns' ] } } },
      plateCols: { type: Number, default: 12 },
      plateRows: { type: Number, default: 8 }
    },
    methods: {
      lookupPlate: function (_) {
        if (this.plateBarcode !== '') {
          this.findPlate()
              .then(this.validatePlate)
              .catch(this.badState)
        } else {
          this.plate = null
          this.state = 'empty'
        }
      },
      async findPlate () {
        this.state = 'searching'
        console.log('this.plateType = ' + this.plateType)
        const plate = (
          await this.api.findAll(this.plateType, {
            include: this.includes,
            filter: { barcode: this.plateBarcode },
            select: this.selects
          })
        ).data[0]
        return plate
      },
      validatePlate: function (plate) {
        if (plate === undefined) {
          this.plate = null
          this.badState({ message: "Could not find plate" })
        } else {
          this.plate = plate
          if (this.incorrectSize(plate)) {
            this.badState({ message: `The plate should be ${this.plateCols}×${this.plateRows} wells in size` })
          } else {
            this.goodState({ message: "Great!" })
          }
        }
      },
      incorrectSize: function(plate) {
        return plate.number_of_columns !== this.plateCols ||
               plate.number_of_rows !== this.plateRows
      },
      badState: function(err) {
        this.state = 'invalid'
        this.invalidFeedback = err.message
      },
      goodState: function(msg) {
        this.state = 'valid'
        this.validFeedback = "Great!"
      }
    },
    computed: {
      searching: function() { return this.state === 'searching' }
    },
    watch: {
      state: function() {
        this.$emit('change', { plate: this.plate, state: this.state })
      }
    }
  }
</script>

