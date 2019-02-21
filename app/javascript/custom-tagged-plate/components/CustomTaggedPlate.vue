<template>
  <lb-page>
    <lb-parent-plate-lookup :api="devourApi"
                            :assetUuid="parentUuid"
                            includes="wells,wells.aliquots,wells.aliquots.request,wells.aliquots.request.submission,wells.requests_as_source,wells.requests_as_source.submission"
                            :fields="{ wells: 'uuid,position,aliquots,requests_as_source',
                                      aliquots: 'request',
                                      requests: 'uuid,submission',
                                      submissions: 'uuid,name' }"
                            @change="parentPlateLookupUpdated">
    </lb-parent-plate-lookup>
    <lb-tag-groups-lookup :api="devourApi"
                          @change="tagGroupsLookupUpdated">
    </lb-tag-groups-lookup>
    <lb-main-content v-if="parentPlate">
      <lb-parent-plate-view :caption="plateViewCaption" :rows="numberOfRows" :columns="numberOfColumns" :wells="childWells"></lb-parent-plate-view>
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
                                                 :tag1GroupOptions="tag1GroupOptions"
                                                 :tag2GroupOptions="tag2GroupOptions"
                                                 :numberOfTags="numberOfTags"
                                                 :numberOfTargetWells="numberOfTargetWells"
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
  import { calculateTagLayout } from 'custom-tagged-plate/tagLayoutFunctions'

  export default {
    name: 'CustomTaggedPlate',
    data () {
      return {
        devourApi: devourApi({ apiUrl: this.sequencescapeApi }, resources),
        plateViewCaption: 'Modify the tag layout for the new plate using options on the right',
        state: 'searching',
        parentPlate: null,
        tagGroupsList: null,
        progressMessageParent: 'Fetching parent plate details...',
        progressMessageTags: 'Fetching tag groups...',
        errorMessages: [],
        tag1GroupId: null,
        tag2GroupId: null,
        walkingBy: null,
        direction: null,
        startAtTagNumber: null,
        tagsPerWellOption: 1
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
        this.parentPlate = null
        if(data) {
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
      tagParamsUpdated(updatedFormData) {
        this.tag1GroupId      = updatedFormData.tag1GroupId
        this.tag2GroupId      = updatedFormData.tag2GroupId
        this.walkingBy        = updatedFormData.walkingBy
        this.direction        = updatedFormData.direction
        this.startAtTagNumber = updatedFormData.startAtTagNumber
      },
      extractSubmissionIdFromWell(well) {
        let submId

        if(well.requests_as_source[0] && well.requests_as_source.submission) {
          submId = well.requests_as_source[0].submission.id
          // TODO loop through additional requests if any? do we take first submission id we find?
        }

        if(!submId) {
          // backup method of getting to submission if primary route fails
          if(well.aliquots[0] && well.aliquots[0].request && well.aliquots[0].request.submission) {
            submId = well.aliquots[0].request.submission.id
            // TODO loop through additional aliquots if any? do we take first submission id we find?
          }
        }

        return submId
      },
      applyTagIndexesToWells(tagLayout) {
        let invalidCount = 0
        let childWells = {}
        const parentWells = this.parentWells

        Object.keys(tagLayout).forEach(function (key) {
          childWells[key] = { ... parentWells[key]}
          if(tagLayout[key] === -1) {
            childWells[key]['tagIndex'] = 'X'
            invalidCount++
          } else {
            childWells[key]['tagIndex'] = tagLayout[key].toString()
          }
        })

        if(invalidCount > 0) {
          this.state = 'invalid'
        } else {
          this.state = 'valid'
        }

        return childWells
      },
      coreTagGroupOptions() {
        let options = []

        const tgs = Object.values(this.tagGroupsList)
        tgs.forEach(function (tg) {
          options.push({ value: tg.id, text: tg.name })
        })

        return options
      },
      calcNumTagsForPooledPlate() {
        let numTargets = 0

        const parentWells = this.parentWells

        let poolTotals = {}
        Object.keys(parentWells).forEach(function (key) {
          let poolIndex = parentWells[key].poolIndex
          poolTotals[poolIndex] = (poolTotals[poolIndex]+1) || 1
        })
        let poolTotalValues = Object.values(poolTotals)
        numTargets = Math.max(...poolTotalValues)

        return numTargets
      },
      calcNumTagsForSeqPlate() {
        let numTargets = 0

        const parentWells = this.parentWells
        Object.keys(parentWells).forEach(function (key) {
          if(parentWells[key].aliquotCount > 0) { numTargets++ }
        })

        return numTargets
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

        // TODO do we also need to set a scanned Tag Plate as 'exhausted' if it was 'available'? Yes.
      }
    },
    computed: {
      numberOfRows: function () {
        let numRows

        if(this.parentPlate) {
          numRows = this.parentPlate.number_of_rows
        }

        return numRows
      },
      numberOfColumns: function () {
        let numCols

        if(this.parentPlate) {
          numCols = this.parentPlate.number_of_columns
        }

        return numCols
      },
      parentWells: function () {
        let wells = {}

        if(!this.parentPlate) {
          return wells
        }

        let submIds = []
        this.parentPlate.wells.forEach((well) => {
          const wellPosn = well.position.name

          if(!well.aliquots) {
            wells[wellPosn] = { position: wellPosn, aliquotCount: 0, poolIndex: null }
            return
          }

          const submId = this.extractSubmissionIdFromWell(well)
          if(!submId) {
            console.log('Error: Submission Id not found for well')
            // TODO what to do here? error message? should not happen
            wells[wellPosn] = { position: wellPosn, aliquotCount: well.aliquots.length, poolIndex: null }
            return
          }

          if(!submIds.includes(submId)) {
            submIds.push(submId)
          }

          const wellPoolIndex = submIds.indexOf(submId) + 1
          wells[wellPosn] = { position: wellPosn, aliquotCount: well.aliquots.length, poolIndex: wellPoolIndex }
        })

        return wells
      },
      childWells: function () {
        let newWells = {}

        if(this.parentWells && this.parentWells !== {}) {
          if(this.tagGroupsList) {
            const data = {
              wells: Object.values(this.parentWells),
              plateDims: { number_of_rows: this.parentPlate.number_of_rows, number_of_columns: this.parentPlate.number_of_columns },
              tag1Group: this.tagGroupsList[this.tag1GroupId],
              tag2Group: this.tagGroupsList[this.tag2GroupId],
              walkingBy: this.walkingBy,
              direction: this.direction,
              startAtTagNumber: this.startAtTagNumber
            }

            let tagLayout = calculateTagLayout(data)

            if(tagLayout) {
              newWells = this.applyTagIndexesToWells(tagLayout)
            } else {
              newWells = { ...this.parentWells }
            }
          } else {
            newWells = { ...this.parentWells }
          }
        }

        return newWells
      },
      tag1GroupOptions: function () {
        let options = []

        if(this.tagGroupsList && Object.keys(this.tagGroupsList).length > 0) {
          options = this.coreTagGroupOptions().slice()
          options.unshift({ value: null, text: 'Please select an i7 Tag 1 group...' })
        }

        return options
      },
      tag2GroupOptions: function () {
        let options = []

        if(this.tagGroupsList && Object.keys(this.tagGroupsList).length > 0) {
          options = this.coreTagGroupOptions().slice()
          options.unshift({ value: null, text: 'Please select an i5 Tag 2 group...' })
        }

        return options
      },
      numberOfTags: function () {
        let numTags = 0
        const tagGrps = this.tagGroupsList
        const tag1Id = this.tag1GroupId
        const tag2Id = this.tag2GroupId

        if(tagGrps && Object.keys(tagGrps).length > 0) {
          if(tag1Id) {
            const tag1Grp = tagGrps[tag1Id]
            numTags = Object.keys(tag1Grp.tags).length
          } else if(tag2Id) {
            const tag2Grp = tagGrps[tag2Id]
            numTags = Object.keys(tag2Grp.tags).length
          }
        }

        return numTags
      },
      numberOfTargetWells: function () {
        let numTargets = 0

        if(this.parentWells) {
          if(this.walkingBy === 'by_plate_seq') {
            numTargets = this.calcNumTagsForSeqPlate()
          } else if(this.walkingBy === 'by_plate_fixed') {
            numTargets = Object.keys(this.parentWells).length
          } else if(this.walkingBy === 'by_pool') {
            numTargets = this.calcNumTagsForPooledPlate()
          }
        }
        return numTargets
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
