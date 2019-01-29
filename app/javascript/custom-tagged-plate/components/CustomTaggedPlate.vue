<template v-if="state === 'searching'">
  <lb-page>
    <lb-loading-modal :message="progressMessage"></lb-loading-modal>
  </lb-page>
</template>
<template v-else>
  <lb-page v-if="parentPlate">
    <lb-main-content>
      <lb-plate :caption="createCaption" :rows="numberOfRows" :columns="numberOfColumns" :wells="childWells"></lb-plate>
      <lb-custom-tagged-plate-details v-bind:childWells="childWells"></lb-custom-tagged-plate-details>
    </lb-main-content>
    <lb-sidebar>
      <b-container fluid>
        <b-row>
          <b-col>
            <lb-custom-tagged-plate-manipulation @tagparamsupdated="tagParamsUpdated"></lb-custom-tagged-plate-manipulation>
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

  export default {
    name: 'CustomTaggedPlate',
    data () {
      return {
        devourApi: devourApi({ apiUrl: this.sequencescapeApi }, resources),
        state: 'searching',
        parentPlate: null,
        childWells: {},
        progressMessage: '',
        byPoolPlateOption: ''
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
      this.lookupParentPlate()
    },
    methods: {
      lookupParentPlate: function (_) {
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
        console.log('end lookupParentPlate, state = ' + this.state)
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
          this.initialiseChildPlateWells()
          this.state = 'loaded'
        }
      },
      parentPlateInvalid() {
        this.parentPlate = null
        this.progressMessage = "Could not find parent plate details"
        this.state = 'unavailable'
      },

      initialiseChildPlateWells() {
        this.childWells = this.parentWells
      },
      recalculateChildPlateWells() {
        this.initialiseChildPlateWells()
        // TODO takes values from manipulation component to recalculate child wells
        // called each time something in the manipulation component is changed
        // new version of childWells triggers a re-display in plate and details components
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
        // TODO store these updated values locally and trigger recalculateChildPlateWells
      },
      submit() {
        console.log('submit called')
        this.state = 'busy'
        // TODO: submit new custom tagged plate creation to sequencescape with tags
      }
    },
    computed: {
      numberOfRows() {
        if(this.parentPlate === null) { return null }
        return this.parentPlate.number_of_rows
      },
      numberOfColumns() {
        if(this.parentPlate === null) { return null }
        return this.parentPlate.number_of_columns
      },
      parentWells() {
        if(this.parentPlate === null) { return {} }
        var wells = {}
        for (var i = 0; i <= this.parentPlate.wells.length - 1; i++) {
            var wellPosn = this.parentPlate.wells[i].position.name
            wells[wellPosn] = { pool_index: i }
        }
        console.log('parentWells:')
        console.log(wells)
        return wells
      },
      createCaption() { return 'Modify the tag layout for the new plate using options on the right' },
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
