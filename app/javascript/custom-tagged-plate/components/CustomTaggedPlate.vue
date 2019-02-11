<template>
  <lb-page>
    <lb-parent-plate-lookup :api="devourApi"
                            :assetUuid="parentUuid"
                            :includes="'wells.aliquots'"
                            @change="parentPlateLookupUpdated">
    </lb-parent-plate-lookup>
    <lb-tag-groups-lookup :api="devourApi"
                          @change="tagGroupsLookupUpdated">
    </lb-tag-groups-lookup>
    <lb-main-content v-if="parentPlate">
      <lb-parent-plate-view :caption="createCaption" :rows="numberOfRows" :columns="numberOfColumns" :wells="childWells"></lb-parent-plate-view>
      <lb-custom-tagged-plate-details></lb-custom-tagged-plate-details>
    </lb-main-content>
    <lb-main-content v-else>
      <lb-loading-modal-plate :message="progressMessageParent" :key="1"></lb-loading-modal-plate>
    </lb-main-content>
    <lb-sidebar v-if="tagGroupsList">
      <b-container fluid>
        <b-row>
          <b-col>
            <lb-custom-tagged-plate-manipulation :api="devourApi"
                                                 :tag1GroupOptions="compTag1GroupOptions"
                                                 :tag2GroupOptions="compTag2GroupOptions"
                                                 :startAtTagOptions="compStartAtTagOptions"
                                                 @tagparamsupdated="tagParamsUpdated">
            </lb-custom-tagged-plate-manipulation>
            <div class="form-group form-row">
              <b-button name="custom_tagged_plate_submit_button" id="custom_tagged_plate_submit_button" :disabled="disabled" :variant="buttonStyle" size="lg" block @click="submit">{{ buttonText }}</b-button>
            </div>
          </b-col>
        </b-row>
      </b-container>
    </lb-sidebar>
    <lb-sidebar v-else>
      <lb-loading-modal-tag-groups :message="progressMessageTags" :key="2"></lb-loading-modal-tag-groups>
    </lb-sidebar>
  </lb-page>
</template>

<script>

  import Plate from 'shared/components/Plate'
  import AssetLookupByUuid from 'shared/components/AssetLookupByUuid'
  import TagGroupsLookup from 'shared/components/TagGroupsLookup'
  import LoadingModal from 'shared/components/LoadingModal'
  import CustomTaggedPlateDetails from './CustomTaggedPlateDetails.vue'
  import CustomTaggedPlateManipulation from './CustomTaggedPlateManipulation.vue'
  import { wellCoordinateToName } from 'shared/wellHelpers'
  import Vue from 'vue'
  import devourApi from 'shared/devourApi'
  import resources from 'shared/resources'

  export default {
    name: 'CustomTaggedPlate',
    data () {
      return {
        devourApi: devourApi({ apiUrl: this.sequencescapeApi }, resources),
        state: 'searching',
        parentPlate: null,
        tagGroupsList: null,
        progressMessageParent: 'Fetching parent plate details...',
        progressMessageTags: 'Fetching tag groups...',
        startAtTagMin: 1,
        startAtTagMax: 96,
        startAtTagStep: 1,
        startAtTagOptions: {},
        errorMessages: [],
        form: {
          tagPlateBarcode: null,
          tag1GroupId: null,
          tag2GroupId: null,
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
    methods: {
      parentPlateLookupUpdated(data) {
        console.log('parentPlateLookupUpdated: data = ', data)
        this.parentPlate = null
        if(data) {
          console.log('parent lookup state = ', data['state'])
          if(data['state'] === 'searching') {
            return
          } else {
            if(data['state'] === 'valid') {
              // TODO more defensive checks here? or in parent plate lookup validate
              this.parentPlate = { ...data['asset']}
              this.state = 'loaded'
            } else {
              this.errorMessages.push('Parent plate lookup error: ', data['state'])
              this.state = 'failed'
            }
          }
        } else {
          this.errorMessages.push('Parent plate lookup error: nothing returned')
          this.state = 'failed'
        }
      },
      tagGroupsLookupUpdated(data) {
        this.tagGroupsList = null
        if(data !== null) {
          if(data.state === 'searching') {
            return
          } else if(data.state === 'valid') {
            this.tagGroupsList = { ...data.tagGroupsList }
            console.log('this.tagGroupsList = ', this.tagGroupsList)
            this.state = 'loaded'
          } else {
            this.errorMessages.push('Tag Groups lookup error: ', data['state'])
            this.state = 'failed'
          }
        } else {
          this.errorMessages.push('Tag Groups lookup error: returned data null')
          this.state = 'failed'
        }
      },
      tagParamsUpdated(updatedform) {
        console.log('tagParamsUpdated: called, updatedform values = ')
        console.log(updatedform)
        this.form.tagPlateBarcode   = updatedform.tagPlateBarcode
        this.form.tag1GroupId       = updatedform.tag1GroupId
        this.form.tag2GroupId       = updatedform.tag2GroupId
        this.form.byPoolPlateOption = updatedform.byPoolPlateOption
        this.form.byRowColOption    = updatedform.byRowColOption
        this.form.startAtTagOption  = updatedform.startAtTagOption
        this.form.tagsPerWellOption = updatedform.tagsPerWellOption
      },
      submit() {
        console.log('submit called')
        this.state = 'busy'
        // TODO: submit new custom tagged plate creation to sequencescape with tags

        // see custom_tagged_plate_spec.rb context 'Providing simple solutions'
        // substitutions { 1:2,5:8, etc } tag 1 for 2, 5 for 8 etc.

        //   let(:form_attributes) do
        //   {
        //     purpose_uuid: child_purpose_uuid,
        //     parent_uuid: plate_uuid,
        //     user_uuid: user_uuid,
        //     tag_plate_barcode: tag_plate_barcode,
        //     tag_plate: { asset_uuid: tag_plate_uuid, template_uuid: tag_template_uuid, state: tag_plate_state },
        //     tag_layout: {
        //       user: 'user-uuid',
        //       tag_group: 'tag-group-uuid',
        //       tag2_group: 'tag2-group-uuid',
        //       direction: 'column',
        //       walking_by: 'manual by plate',
        //       initial_tag: '1',
        //       substitutions: {},
        //       tags_per_well: 1
        //     }
        //   }
        // end

        // it 'can be created' do
        //   expect(subject).to be_a LabwareCreators::CustomTaggedPlate
        // end
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
        if(!this.parentPlate) { return {} }
        let wells = {}
        this.parentPlate.wells.forEach((well) => {
          let wellPosn = well.position.name
          wells[wellPosn] = { pool_index: 20 }
        })
        console.log('parentWells = ' + wells)
        return wells
      },
      childWells: function () {
        if(!this.parentPlate) { return {} }
        if(!this.parentPlate.wells) { return {} }
        const wells = {}
        // first initialise wells to match the parent plate
        this.parentPlate.wells.forEach((well) => {
          console.log('well = ' + well)
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
      compTag1GroupOptions: function () {
        if(!this.tagGroupsList || Object.keys(this.tagGroupsList).length === 0) { return null }
        let options = this.coreTagGroupOptions.slice()
        options.unshift({ value: null, text: 'Please select an i7 Tag 1 group...' })
        return options
      },
      compTag2GroupOptions: function () {
        if(!this.tagGroupsList || this.tagGroupsList.length === 0) { return null }
        let options = this.coreTagGroupOptions.slice()
        options.unshift({ value: null, text: 'Please select an i5 Tag 2 group...' })
        return options
      },
      coreTagGroupOptions: function () {
        let options = []
        let tgs = Object.values(this.tagGroupsList)
        tgs.forEach(function (tg) {
          options.push({ value: tg.id, text: tg.name })
        })
        return options
      },
      compStartAtTagOptions: function () {
        // TODO calculate the min/max based on function changes
        const arr = [
          { value: null, text: 'Select which tag index to start at...' }
        ]
        const totalSteps = Math.floor((this.startAtTagMax - this.startAtTagMin)/this.startAtTagStep)
        for (let i = 0; i <= totalSteps; i++ ) {
          let v = i * this.startAtTagStep + this.startAtTagMin
          arr.push({ value: v, text: '' + v})
        }
        console.log('in computed compStartAtTagOptions, new value = ' + JSON.stringify(arr))
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
      'lb-loading-modal-plate': LoadingModal,
      'lb-loading-modal-tag-groups': LoadingModal,
      'lb-parent-plate-lookup': AssetLookupByUuid,
      'lb-tag-groups-lookup': TagGroupsLookup,
      'lb-parent-plate-view': Plate,
      'lb-custom-tagged-plate-details': CustomTaggedPlateDetails,
      'lb-custom-tagged-plate-manipulation': CustomTaggedPlateManipulation
    }
  }
</script>
