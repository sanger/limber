<template v-if="state === 'searching'">
  <lb-page>
    <lb-loading-modal :message="progressMessage"></lb-loading-modal>
  </lb-page>
</template>
<template v-else>
  <lb-page v-if="parentPlate">
    <lb-main-content>
      <lb-plate :caption="createCaption" :rows="numberOfRows" :columns="numberOfColumns" :wells="childWells"></lb-plate>
      <lb-custom-tagged-plate-details></lb-custom-tagged-plate-details>
    </lb-main-content>
    <lb-sidebar>
      <b-container fluid>
        <b-row>
          <b-col>
            <lb-custom-tagged-plate-manipulation :devourApi="devourApi"
                                                 :startAtTagOptions="calcStartAtTagOptions"
                                                 @tagparamsupdated="tagParamsUpdated">
            </lb-custom-tagged-plate-manipulation>
            <div class="form-group form-row">
              <b-button name="custom_tagged_plate_submit_button" id="custom_tagged_plate_submit_button" :disabled="disabled" :variant="buttonStyle" size="lg" block @click="submit">{{ buttonText }}</b-button>
            </div>
          </b-col>
        </b-row>
      </b-container>
    </lb-sidebar>
  </lb-page>
</template>

<script>

  import Plate from 'shared/components/Plate'
  import LoadingModal from 'shared/components/LoadingModal'
  import devourApi from 'shared/devourApi'
  import resources from 'shared/resources'
  import CustomTaggedPlateDetails from './CustomTaggedPlateDetails.vue'
  import CustomTaggedPlateManipulation from './CustomTaggedPlateManipulation.vue'
  import { wellCoordinateToName } from 'shared/wellHelpers'

  export default {
    name: 'CustomTaggedPlate',
    data () {
      return {
        devourApi: devourApi({ apiUrl: this.sequencescapeApi }, resources),
        state: 'searching',
        parentPlate: null,
        progressMessage: '',
        startAtTagMin: 1,
        startAtTagMax: 96,
        startAtTagStep: 1,
        startAtTagOptions: {},
        form: {
          tagPlateBarcode: null,
          tag1Group: null,
          tag2Group: null,
          byPoolPlateOption: null,
          byRowColOption: null,
          startAtTagOption: 1,
          tagsPerWellOption: 1
        }
      }
    },
    props: {
      sequencescapeApi: { type: String, default: 'http://localhost:3000/api/v2' },
      purposeUuid: { type: String, required: true },
      targetUrl: { type: String, required: true },
      parentUuid: { type: String, required: true }
    },
    created: function () {
      this.progressMessage = "Fetching parent plate details..."
      this.fetchParentPlate()
      // this.progressMessage = "Fetching tag groups list..."
      // this.fetchTagGroups()
    },
    methods: {
      fetchParentPlate: function (_) {
        if (this.parentUuid !== '') {
          console.log('uuid = ' + this.parentUuid)
          this.findPlate()
              .then(this.validateParentPlate)
              .catch(() => {
                console.log('in catch')
                this.parentPlateInvalid()
              })
        } else {
          console.log('in else')
          this.parentPlateInvalid()
        }
        console.log('end fetchParentPlate, state = ' + this.state)
      },
      async findPlate () {
        console.log('in findPlate')
        this.state = 'searching'
        const plate = (
          await this.devourApi.findAll('plate',{
            include: 'wells.aliquots',
            filter: { uuid: this.parentUuid },
            select: { plates: [ 'labware_barcode', 'uuid', 'number_of_rows', 'number_of_columns' ] }
          })
        ).data[0]
        console.log('plate = ' + plate)
        return plate
      },
      validateParentPlate: function (plate) {
        if (plate === undefined) {
          this.parentPlateInvalid()
        } else {
          this.parentPlate = plate
          this.progressMessage = "Found parent plate details"
          this.state = 'loaded'
        }
      },
      parentPlateInvalid() {
        this.parentPlate = null
        this.progressMessage = "Could not find parent plate details"
        this.state = 'unavailable'
      },
      tagParamsUpdated(updatedform) {
        console.log('in parent tagParamsUpdated called, updatedform values = ')
        console.log('tagPlateBarcode = ' + updatedform.tagPlateBarcode)
        console.log('tag1Group = ' + updatedform.tag1Group)
        console.log('tag2Group = ' + updatedform.tag2Group)
        console.log('byPoolPlateOption = ' + updatedform.byPoolPlateOption)
        console.log('byRowColOption = ' + updatedform.byRowColOption)
        console.log('startAtTagOption = ' + updatedform.startAtTagOption)
        console.log('tagsPerWellOption = ' + updatedform.tagsPerWellOption)
        this.form.tagPlateBarcode   = updatedform.tagPlateBarcode
        this.form.tag1Group         = updatedform.tag1Group
        this.form.tag2Group         = updatedform.tag2Group
        this.form.byPoolPlateOption = updatedform.byPoolPlateOption
        this.form.byRowColOption    = updatedform.byRowColOption
        this.form.startAtTagOption  = updatedform.startAtTagOption
        this.form.tagsPerWellOption = updatedform.tagsPerWellOption
      },
      submit() {
        console.log('submit called')
        this.state = 'busy'
        // TODO: submit new custom tagged plate creation to sequencescape with tags
      }
    },
    computed: {
      numberOfRows: function () {
        return this.parentPlate.number_of_rows || null
      },
      numberOfColumns: function () {
        return this.parentPlate.number_of_columns || null
      },
      parentWells: function () {
        if(this.parentPlate === null) { return {} }
        var wells = {}
        this.parentPlate.wells.forEach((well) => {
          let wellPosn = well.position.name
          wells[wellPosn] = { pool_index: 20 }
        })
        return wells
      },
      childWells: function () {
        const wells = {}

        // first initialise wells to match the parent plate
        this.parentPlate.wells.forEach((well) => {
          let wellPosn = well.position.name
          wells[wellPosn] = { ... this.parentWells[wellPosn]}
        })

        // TODO - split transformations out into functions (can be in seperate file imported) and call functions here.
        // TODO - function for tag plate scanned
        // TODO - function for tag group 1 selected
        // TODO - function for tag group 2 selected
        // TODO - function for by pool/plate seq/plate fixed selected
        // TODO - function for by row/column selected
        // TODO - function for start at index number selected

        // TODO delete this - just an example of triggering updates
        if(this.form.byPoolPlateOption === 'by_plate_seq') {
          let index = 1
          this.parentPlate.wells.forEach((well) => {
            let wellPosn = well.position.name
            wells[wellPosn]['tagIndex'] = index
            index++
          })
          this.startAtTagMin = 4
          this.startAtTagStep = 2
        }

        return wells
      },
      createCaption: function () {
        return 'Modify the tag layout for the new plate using options on the right'
      },
      calcStartAtTagOptions: function () {
        // TODO calculate the min/max based on function changes
        const arr = [
          { value: null, text: 'Select which tag index to start at...' }
        ]
        const totalSteps = Math.floor((this.startAtTagMax - this.startAtTagMin)/this.startAtTagStep)
        for (let i = 0; i <= totalSteps; i++ ) {
          let v = i * this.startAtTagStep + this.startAtTagMin
          arr.push({ value: v, text: '' + v})
        }
        console.log('in computed calcStartAtTagOptions, new value = ' + JSON.stringify(arr))
        return arr
      },
      buttonText() {
        return {
            'loaded': 'Set up plate Tag layout...',
            'updating': 'Set up plate Tag layout...',
            'valid': 'Create new Custom Tagged Plate in Sequencescape',
            'invalid': 'Set up plate Tag layout...',
            'busy': 'Sending...',
            'success': 'Custom Tagged plate successfully created',
            'failure': 'Failed to create Custom Tag Plate, retry?'
        }[this.state]
      },
      buttonStyle() {
        return {
          'loaded': 'secondary',
          'updating': 'secondary',
          'valid': 'primary',
          'invalid': 'danger',
          'busy': 'outline-primary',
          'success': 'success',
          'failure': 'danger'
        }[this.state]
      },
      disabled() {
        return {
          'loaded': true,
          'updating': true,
          'valid': false,
          'invalid': true,
          'busy': true,
          'success': true,
          'failure': false
        }[this.state]
      },
    },
    components: {
      'lb-loading-modal': LoadingModal,
      'lb-plate': Plate,
      'lb-custom-tagged-plate-details': CustomTaggedPlateDetails,
      'lb-custom-tagged-plate-manipulation': CustomTaggedPlateManipulation
    }
  }
</script>
