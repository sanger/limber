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
      api: { required: false },
      label: { type: String, default: 'Plate'},
      description: { type: String },
      plateType: { type: String, default: 'plate' },
      includes: { default: () => { return '' } },
      fields: { default: () => { return { plates: 'labware_barcode,uuid,number_of_rows,number_of_columns' } } },
      plateCols: { type: Number, default: 12 },
      plateRows: { type: Number, default: 8 }
    },
    methods: {
      lookupPlate: function (_) {
        if (this.plateBarcode !== '') {
          this.findPlate()
              .then(
                this.plateType === 'qcable' ? this.validateQcable : this.validatePlate
              )
              .catch(this.apiError)
        } else {
          this.plate = null
          this.state = 'empty'
        }
      },
      async findPlate () {
        this.state = 'searching'
        console.log(this.api)
        console.log('includes = ' + JSON.stringify(this.includes))
        console.log('fields = ' + JSON.stringify(this.fields))
        const plate = (
          await this.api.findAll(this.plateType, {
            include: this.includes,
            filter: { barcode: this.plateBarcode },
            fields: this.fields
          })
        )
        console.log('plate:')
        console.log(JSON.stringify(plate))
        console.log('plate.data[0]:')
        console.log(JSON.stringify(plate.data[0]))
        return plate.data[0]
      },
      validatePlate: function (plate) {
        if (plate === undefined) {
          console.log('plate undefined')
          this.plate = null
          this.badState({ message: 'Could not find plate' })
        } else {
          this.plate = plate
          if (this.incorrectSize(plate)) {
            console.log('plate incorrect size')
            this.badState({ message: `The plate should be ${this.plateCols}×${this.plateRows} wells in size` })
          } else {
            console.log('plate valid')
            this.goodState({ message: 'Valid!' })
          }
        }
      },
      validateQcable: function (plate) {
        if (plate === undefined) {
          console.log('qcable undefined')
          this.plate = null
          this.badState({ message: 'Could not find plate' })
        } else {
          this.plate = plate
          if(this.incorrectState(plate)) {
            console.log('qcable incorrect state')
            this.badState({ message: 'The tag plate should be in available or exhausted state' })
          } else {
            if(this.incorrectWalkingBy(plate)) {
              console.log('qcable incorrect walking by')
              this.badState({ message: 'The tag plate should have a walking by of wells by plate' })
            } else {
              console.log('qcable valid')
              this.goodState({ message: 'Valid!' })
            }
          }
        }
      },
      incorrectSize: function(plate) {
        return plate.number_of_columns !== this.plateCols ||
               plate.number_of_rows !== this.plateRows
      },
      incorrectState: function(plate) {
        console.log('plate state = ' + plate.state)
        if(plate.state === 'available') { return false }
        if(plate.state === 'exhausted') { return false }
        return true
      },
      incorrectWalkingBy: function(plate) {
        console.log('plate tag layout walking by = ' + plate.lot.tag_layout_template.walking_by)
        return plate.lot.tag_layout_template.walking_by !== 'wells of plate'
      },
      apiError: function(err) {
        if (!err) {
          console.log('unknown api error')
          this.badState({message: 'Unknown error'})
        } else if (err[0]) {
          console.log('api error with msg')
          const message = `${err[0].title}: ${err[0].detail}`
          this.badState({ message })
        } else {
          console.log('api error')
          this.badState(err)
        }
      },
      badState: function(err) {
        this.state = 'invalid'
        console.log('setting invalid feedback')
        this.invalidFeedback = err.message || 'Unknown error'
      },
      goodState: function(msg) {
        this.state = 'valid'
        console.log('setting valid feedback')
        this.validFeedback = "Valid!"
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

