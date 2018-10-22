<template>
  <b-form-group :label="label"
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
      plateApi: { required: true },
      label: { type: String, default: 'Plate'},
      description: { type: String }
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
        const plate = (await this.plateApi.where({barcode: this.plateBarcode}).first()).data
        return plate
      },
      validatePlate: function (plate) {
        if (plate === null) {
          this.plate = null
          this.badState({ message: "Could not find plate" })
        } else {
          this.plate = plate
          this.goodState({ message: "Great!" })
        }
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

