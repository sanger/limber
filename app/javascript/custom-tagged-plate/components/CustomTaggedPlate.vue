<template>
  <lb-page>
    <lb-loading-modal v-if="loading" :message="progressMessage"></lb-loading-modal>
    <lb-main-content v-else >
      <lb-plate :caption="createCaption" :rows="numberOfRows" :columns="numberOfColumns" :wells="childWells"></lb-plate>
      <lb-custom-tagged-plate-details v-bind:childWells="childWells"></lb-custom-tagged-plate-details>
    </lb-main-content>
    <lb-sidebar>
      <b-container fluid>
        <b-row>
          <b-col>
            <lb-custom-tagged-plate-manipulation></lb-custom-tagged-plate-manipulation>
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

  import CustomTaggedPlateDetails from './CustomTaggedPlateDetails.vue'
  import CustomTaggedPlateManipulation from './CustomTaggedPlateManipulation.vue'

  export default {
    name: 'CustomTaggedPlate',
    data () {
      return {
        state: 'pending',
        parentWells: null,
        childWells: null,
        numberOfColumns: 12,
        numberOfRows: 8,
        loading: false,
        progressMessage: ''
      }
    },
    props: {
      sequencescapeApi: { type: String, default: 'http://localhost:3000/api/v2' },
      purposeUuid: { type: String, required: true },
      targetUrl: { type: String, required: true },
      parentUuid: { type: String, required: true }
    },
    created: function () {
      this.loading = true
      this.progressMessage = "Fetching parent plate details..."
      this.getParentPlateDetails()
    },
    methods: {
      getParentPlateDetails() {
        console.log('in getParentPlateDetails')
        // TODO: abstract out axios interaction to a separate module
        this.$axios({
          method: 'get',
          url: '/plates?filter[uuid]=' + this.parentUuid + '&limit=1&include=wells.aliquots'
        }).then(response => {
            console.log('response:')
            console.log(response.data)
            this.progressMessage = response.data.message
            this.parentWells = this.parsePlateResponseData(response.data)
            // TODO keep parent plate wells separate from the child plate planned wells tag layout
            // where should we initialise (and re-initialise) the child wells object?
            // how do we pass this to the child components for manipulation/display?
            this.initialiseChildPlateWells()
            this.childWells = this.parentWells
          })
          // .then(() => {
          //   console.log('success')
          // })
          .catch(error => {
            console.log('error:')
            console.log(error)
          })
          .finally(() => {
            this.loading = false
          })
      },
      parsePlateResponseData(data) {
        console.log('in parsePlateResponseData')
        this.numberOfRows    = data.data[0].attributes.number_of_rows
        this.numberOfColumns = data.data[0].attributes.number_of_columns
        var humanBarcode     = data.data[0].attributes.labware_barcode.human_barcode

        var includedLen = data.included.length
        var wells = {}
        for (var i = 0; i <= data.included.length - 1; i++) {
          if(data.included[i].type == 'wells') {
            // attributes e.g.
            // {uuid: "927bd9d6-b4f7-11e8-8d78-3c4a9275d6c8", name: "DN540251D:H12", position: {name: "H12"}, state: "passed"}
            var wellPosn = data.included[i].attributes.position.name
            wells[wellPosn] = { pool_index: 1 }
          }
          // else if(data.included[i].type == 'aliquots' {
          //   // attributes e.g.
          //   // {tag_oligo: null, tag_index: null, tag2_oligo: null, tag2_index: null, suboptimal: false}
          //   var numAliquots = data.included[i].relationships.aliquots.data.length
          //   console.log('num aliquots:' + numAliquots)
          // }
        }
        // console.log('parsePlateResponseData wells:')
        // console.log(wells)
        return wells
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
      updateChildWells(form) {
        console.log('parent updateChildWells called, form values = ')
        console.log('tagPlateBarcode = ' + form.tagPlateBarcode)
        console.log('tag1Group = ' + form.tag1Group)
        console.log('tag2Group = ' + form.tag2Group)
        console.log('byPoolPlateOption = ' + form.byPoolPlateOption)
        console.log('byRowColOption = ' + form.byRowColOption)
        console.log('startAtTagOption = ' + form.startAtTagOption)
        console.log('tagsPerWellOption = ' + form.tagsPerWellOption)
      },
      submit() {
        console.log('submit called')
        this.state = 'busy'
        // TODO: details?
      },
      isSetupInvalid() {
        console.log('isSetupInvalid called')
        // TODO: details?
        return false
      }
    },
    computed: {
      createCaption() { return 'Modify the tag layout for the new plate using options on the right' },
      buttonText() {
        return {
            'pending': 'Create new Tagged Plate in Sequencescape',
            'busy': 'Sending...',
            'success': 'Tagged plate successfully created',
            'failure': 'Failed to create Tag Plate, retry?'
        }[this.state]
      },
      buttonStyle() {
        return {
          'pending': 'primary',
          'busy': 'outline-primary',
          'success': 'success',
          'failure': 'danger'
        }[this.state]
      },
      disabled() {
        return {
          'pending': this.isSetupInvalid(),
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
