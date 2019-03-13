<template>
  <lb-page>
    <lb-main-content v-if="parentPlate">
      <lb-parent-plate-view :caption="plateViewCaption" :rows="numberOfRows" :columns="numberOfColumns" :wells="childWells" @onwellclicked="onWellClicked"></lb-parent-plate-view>
      <!-- if no aliquot in well can do nothing but show basic info -->
      <!-- if no tag in well do what? allow tag substitution -->
      <!-- if tag want to show any existing substitution and allow change (show original tag and sub tag in number input) -->
      <!-- if tag but no substitution show empty subs tag number input -->
      <!-- number input range is same as full number of tags list range -->
      <!-- validations on Ok: -->
      <!-- * valid tag number from range -->
      <!-- * NB. can be same as original tag (to allow reset) -->
      <!-- processes on Ok: -->
      <!-- * update/new/remove substitution for the well key e.g. A1: { 1:5 } -->
      <!-- * substitutions change should trigger update on childwells with new tag which should trigger update on plate view -->
      <!-- * substitutions are prop in details panel so will trigger it to update -->
      <!-- * computed tag clash checks are triggered by change in childwells and will highlight matching tags in plate and set state invalid -->
      <!-- TODO change max from numberOfTags to highest map id number -->
      <!-- TODO change min from 1 to lowest map id number -->
      <!-- TODO v-if messages show here e.g. do we have Tag Clash info? Or if No tag. -->
      <b-modal v-if="wellModalDetails"
              id="well_modal"
              :title="wellModalTitle"
              v-model="isWellModalVisible"
              @ok="handleWellModalOk"
              @shown="handleWellModalShown">
        <form @submit.stop.prevent="handleWellModalSubmit">
          <b-container fluid>
            <b-row class="form-group form-row">
              <b-col>
                <b-form-group id="original_tag_number_group"
                              label="Original tag:"
                              label-for="original_tag_number_input"
                              readonly="true">
                  <b-form-input id="original_tag_number_input"
                                type="number"
                                v-bind:value="wellModalDetails.originalTag"
                                readonly>
                  </b-form-input>
                </b-form-group>
              </b-col>
            </b-row>
            <b-row class="form-group form-row">
              <b-col>
                <b-form-group id="substitute_tag_number_group"
                              label="Substitute tag:"
                              label-for="substitute_tag_number_input"
                              :invalid-feedback="substituteTagInvalidFeedback"
                              :valid-feedback="substituteTagValidFeedback"
                              :state="substituteTagState">
                  <b-form-input id="substitute_tag_number_input"
                                type="number"
                                min="1"
                                :max="numberOfTags"
                                step="1"
                                placeholder="Enter tag number to substitute"
                                :state="substituteTagState"
                                v-model="substituteTagId"
                                ref="focusThis">
                  </b-form-input>
                </b-form-group>
              </b-col>
            </b-row>
          </b-container>
        </form>
      </b-modal>
      <lb-custom-tagged-plate-details :tagSubstitutions="tagSubstitutions"
                                      @removetagsubstitution="removeTagSubstitution">
      </lb-custom-tagged-plate-details>
    </lb-main-content>
    <lb-main-content v-else>
      <lb-loading-modal-plate :message="progressMessageParent" :key="1"></lb-loading-modal-plate>
      <lb-parent-plate-lookup :api="devourApi"
                            :assetUuid="parentUuid"
                            includes="wells,wells.aliquots,wells.aliquots.request,wells.aliquots.request.submission,wells.requests_as_source,wells.requests_as_source.submission"
                            :fields="{ wells: 'uuid,position,aliquots,requests_as_source',
                                      aliquots: 'request',
                                      requests: 'uuid,submission',
                                      submissions: 'uuid,name,used_tags' }"
                            @change="parentPlateLookupUpdated">
    </lb-parent-plate-lookup>
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
                                                 :tagsPerWell="tagsPerWellAsNumber"
                                                 @tagparamsupdated="tagParamsUpdated">
            </lb-custom-tagged-plate-manipulation>
            <div class="form-group form-row">
              <b-button name="custom_tagged_plate_submit_button" id="custom_tagged_plate_submit_button" :disabled="buttonDisabled" :variant="buttonStyle" size="lg" block @click="createPlate">{{ buttonText }}</b-button>
            </div>
          </b-col>
        </b-row>
      </b-container>
    </lb-sidebar>
    <lb-sidebar v-else>
      <lb-loading-modal-tag-groups :message="progressMessageTags" :key="2"></lb-loading-modal-tag-groups>
      <lb-tag-groups-lookup :api="devourApi"
                          @change="tagGroupsLookupUpdated">
    </lb-tag-groups-lookup>
    </lb-sidebar>
  </lb-page>
</template>

<script>

  import Plate from 'shared/components/Plate.vue'
  import AssetLookupByUuid from 'shared/components/AssetLookupByUuid.vue'
  import TagGroupsLookup from 'shared/components/TagGroupsLookup.vue'
  import LoadingModal from 'shared/components/LoadingModal.vue'
  import CustomTaggedPlateDetails from './CustomTaggedPlateDetails.vue'
  import CustomTaggedPlateManipulation from './CustomTaggedPlateManipulation.vue'
  import { wellCoordinateToName } from 'shared/wellHelpers.js'
  import Vue from 'vue'
  import devourApi from 'shared/devourApi'
  import resources from 'shared/resources'
  import { calculateTagLayout } from 'custom-tagged-plate/tagLayoutFunctions.js'

  export default {
    name: 'CustomTaggedPlate',
    data () {
      return {
        devourApi: devourApi({ apiUrl: this.sequencescapeApi }, resources),
        plateViewCaption: 'Modify the tag layout for the new plate using options on the right',
        parentPlateState: 'searching',
        tagGroupsState: 'searching',
        creationRequestInProgress: null,
        creationRequestSuccessful: null,
        parentPlate: null,
        tagGroupsList: null,
        progressMessageParent: 'Fetching parent plate details...',
        progressMessageTags: 'Fetching tag groups...',
        tagPlate: null,
        tag1GroupId: null,
        tag2GroupId: null,
        walkingBy: null,
        direction: null,
        offsetTagsBy: null,
        tagSubstitutions: {}, // { 1:2, 5:8 etc}
        tagClashes: {}, // { 'A1': [ 'B3', 'B7' ], 'A5': [ 'submission' ] },
        isWellModalVisible: false,
        wellModalDetails: {},
        substituteTagId: null
      }
    },
    props: {
      sequencescapeApi: { type: String, default: 'http://localhost:3000/api/v2' },
      purposeUuid: { type: String, required: true },
      targetUrl: { type: String, required: true },
      parentUuid: { type: String, required: true },
      tagsPerWell: { type: String, required: true },
      locationObj: { default: () => { return location } }
    },
    methods: {
      parentPlateLookupUpdated(data) {
        this.parentPlate = null
        if(data) {
          if(data['state'] === 'searching') {
            return
          } else {
            if(data['state'] === 'valid') {
              this.parentPlate = { ...data['asset']}
              this.parentPlateState = 'loaded'
            } else {
              console.log('Parent plate lookup error: ', data['state'])
              this.parentPlateState = 'failed'
            }
          }
        } else {
          console.log('Parent plate lookup error: nothing returned')
          this.parentPlateState = 'failed'
        }
      },
      tagGroupsLookupUpdated(data) {
        this.tagGroupsList = null
        if(data !== null) {
          if(data.state === 'searching') {
            return
          } else if(data.state === 'valid') {
            this.tagGroupsList = { ...data.tagGroupsList }
            this.tagGroupsState = 'loaded'
          } else {
            console.log('Tag Groups lookup error: ', data['state'])
            this.tagGroupsState = 'failed'
          }
        } else {
          console.log('Tag Groups lookup error: returned data null')
          this.tagGroupsState = 'failed'
        }
      },
      tagParamsUpdated(updatedFormData) {
        this.tagPlate     = updatedFormData.tagPlate
        this.tag1GroupId  = updatedFormData.tag1GroupId
        this.tag2GroupId  = updatedFormData.tag2GroupId
        this.walkingBy    = updatedFormData.walkingBy
        this.direction    = updatedFormData.direction
        this.offsetTagsBy = updatedFormData.offsetTagsBy
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
      calcNumTagsForGroupByPlate() {
        let numTargets = 0

        const parentWells = this.parentWells
        Object.keys(parentWells).forEach(function (key) {
          if(parentWells[key].aliquotCount > 0) { numTargets++ }
        })

        return numTargets
      },
      createPlate() {
        this.creationRequestInProgress = true

        let payload = {
          plate: {
            purpose_uuid: this.purposeUuid,
            parent_uuid: this.parentUuid,
            tag_layout: {
              tag_group: this.tag1GroupUuid,
              tag2_group: this.tag2GroupUuid,
              direction: this.direction,
              walking_by: this.walkingBy,
              initial_tag: this.offsetTagsBy, // initial tag is zero-based index of the tag within its group
              substitutions: this.tagSubstitutions, // { 1:2,5:8, etc }
              tags_per_well: this.tagsPerWellAsNumber
            },
            tag_plate: {
              asset_uuid: null,
              template_uuid: null,
              state: null
            }
          }
        }
        if(this.tagPlate) {
          payload.plate.tag_plate = {
            asset_uuid: this.tagPlate.uuid,
            template_uuid: this.tagPlate.lot.tag_layout_template.uuid,
            state: this.tagPlate.state
          }
        }

        this.$axios({
          method: 'post',
          url:this.targetUrl,
          headers: {'X-Requested-With': 'XMLHttpRequest'},
          data: payload
        }).then((response)=>{
          // Ajax responses automatically follow redirects, which
          // would result in us receiving the full HTML for the child
          // plate here, which we'd then need to inject into the
          // page, and update the history. Instead we don't redirect
          // application/json requests, and redirect the user ourselves.

          // TODO progress spinner with message
          // this.progressMessage = response.data.message
          this.locationObj.href = response.data.redirect
          this.creationRequestInProgress = false
          this.creationRequestSuccessful = true
          // TODO clear out stored info to reset page? does it forward to new plate?
        }).catch((error)=>{
          // Something has gone wrong
          console.log(error)
          this.creationRequestInProgress = false
          this.creationRequestSuccessful = false
        })
      },
      onWellClicked(wellName) {
        if(this.childWells[wellName].aliquotCount === 0) { return }

        if(!this.childWells[wellName].tagIndex) { return }

        // TODO do we need flag for 'no tag present?' and display message in modal with no tag subs options?

        const origTag = this.tagLayout[wellName]

        this.wellModalDetails = {
          wellName: wellName,
          currentTag: this.childWells[wellName].tagIndex,
          originalTag: origTag,
          substitutionExists: false
        }

        this.substituteTagId = null

        // check if already substituted and if so display that info
        if(origTag in this.tagSubstitutions) {
          this.wellModalDetails.substitutionExists = true
          this.substituteTagId = this.tagSubstitutions[origTag]
        }

        this.isWellModalVisible = true
      },
      handleWellModalShown(e) {
        this.$refs.focusThis.focus()
      },
      handleWellModalOk(evt) {
        // Prevent modal from closing unless conditions are met
        evt.preventDefault()
        // TODO this will not work for just messages e.g. empty well/no tags
        if (!this.substituteTagId) {
          alert('Please enter a tag to substitute then click Ok, or else cancel')
        } else {
          this.isWellModalVisible = false
          this.handleWellModalSubmit()
        }
      },
      handleWellModalSubmit() {
        const origTag = this.wellModalDetails.originalTag

        if(origTag in this.tagSubstitutions && origTag === this.substituteTagId) {
          // because we have changed back to original, delete the substitution from the list
          delete this.tagSubstitutions.origTag
        } else {
          this.tagSubstitutions[origTag] = this.substituteTagId
        }

        // TODO having to create new object to trigger reactivity, why?
        let newTagSubs = { ...this.tagSubstitutions }
        this.tagSubstitutions = newTagSubs
      },
      removeTagSubstitution(origTagId) {
        // TODO having to create new object to trigger reactivity, why?
        let newTagSubs = { ...this.tagSubstitutions }
        delete newTagSubs[origTagId]
        this.tagSubstitutions = newTagSubs
      }
    },
    computed: {
      loadingState() {
        this.parentPlateState
        this.tagGroupsState

        if(this.parentPlateState === 'failed' || this.tagGroupsState === 'failed') {
          return 'failed'
        }
        if(this.parentPlateState === 'searching' || this.tagGroupsState === 'searching') {
          return 'searching'
        }
        if(this.parentPlateState === 'loaded' && this.tagGroupsState === 'loaded') {
          return 'loaded'
        }
      },
      tagsValid() {
        this.loadingState
        this.tagClashes
        this.childWells

        if(this.loadingState !== 'loaded') {
          return false
        }

        // do not check for tag clashes if chromium
        if(this.tagsPerWell !== 4 && Object.keys(this.tagClashes).length > 0) {
          return false
        }

        // valid if all wells with aliquots have tags
        let invalidCount = 0
        Object.keys(this.childWells).forEach((wellName) => {
          if(this.childWells[wellName].aliquotCount > 0) {
            // TODO could set an invalid flag on childWell itself§
            if(!this.childWells[wellName].tagIndex || this.childWells[wellName].tagIndex === 'X') {
              invalidCount++
            }
          }
        })

        return ((invalidCount > 0) ? false : true)
      },
      createButtonState() {
        this.tagsValid
        this.creationRequestInProgress
        this.creationRequestSuccessful

        if(!this.tagsValid) {
          return 'setup'
        } else if(this.creationRequestInProgress === null) {
          return 'pending'
        } else if(this.creationRequestInProgress) {
          return 'busy'
        } else if(this.creationRequestSuccessful) {
          return 'success'
        } else {
          return 'failure'
        }
      },
      numberOfRows() {
        this.parentPlate
        return (this.parentPlate ? this.parentPlate.number_of_rows : null)
      },
      numberOfColumns() {
        this.parentPlate
        return (this.parentPlate ? this.parentPlate.number_of_columns : null)
      },
      tagsPerWellAsNumber() {
        this.tagsPerWell
        return (this.tagsPerWell ? Number.parseInt(this.tagsPerWell) : null)
      },
      parentWells() {
        this.parentPlate

        let wells = {}

        if(!this.parentPlate) {
          return wells
        }

        let submIds = []
        this.parentPlate.wells.forEach((well) => {
          const wellPosn = well.position.name

          if(!well.aliquots || well.aliquots.length === 0) {
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
      parentWellData() {
        this.parentWells
        return (this.parentWells ? Object.values(this.parentWells) : null)
      },
      tag1Group() {
        this.tagGroupsList
        this.tag1GroupId
        return ((this.tagGroupsList && this.tag1GroupId) ? this.tagGroupsList[this.tag1GroupId] : null)
      },
      tag1GroupUuid() {
        this.tag1Group
        return ((this.tag1Group) ? this.tag1Group.uuid : null)
      },
      tag1GroupTags() {
        this.tag1Group
        return (this.tag1Group ? this.tag1Group.tags : null)
      },
      tag2Group() {
        this.tagGroupsList
        this.tag2GroupId
        return ((this.tagGroupsList && this.tag2GroupId) ? this.tagGroupsList[this.tag2GroupId] : null)
      },
      tag2GroupUuid() {
        this.tag2Group
        return ((this.tag2Group) ? this.tag2Group.uuid : null)
      },
      tag2GroupTags() {
        this.tag2Group
        return (this.tag2Group ? this.tag2Group.tags : null)
      },
      arrayTags() {
        this.tag1GroupTags
        this.tag2GroupTags
        if(this.tag1GroupTags) {
          return this.tag1GroupTags
        }
        if(this.tag2GroupTags) {
          return this.tag2GroupTags
        }
        return null
      },
      tagMapIds() {
        this.numberOfTags
        this.arrayTags
        if(this.numberOfTags === 0) { return null }

        if(!this.arrayTags) { return null }

        let arrayMapIds = []
        for (var i = 0; i < this.arrayTags.length; i++) {
          arrayMapIds.push(this.arrayTags[i].index)
        }
        return arrayMapIds
      },
      parentNumberOfRows() {
        this.parentPlate
        return (this.parentPlate ? this.parentPlate.number_of_rows : null)
      },
      parentNumberOfColumns() {
        this.parentPlate
        return (this.parentPlate ? this.parentPlate.number_of_columns : null)
      },
      plateDims() {
        return {
          number_of_rows: this.parentNumberOfRows,
          number_of_columns: this.parentNumberOfColumns
        }
      },
      tagLayout() {
        const inputData = {
          wells: this.parentWellData,
          plateDims: this.plateDims,
          tag1Group: this.tag1Group,
          tag2Group: this.tag2Group,
          walkingBy: this.walkingBy,
          direction: this.direction,
          offsetTagsBy: this.offsetTagsBy
        }

        return calculateTagLayout(inputData)
      },
      childWells() {
        this.parentWells
        this.tagLayout
        this.tagSubstitutions

        if(this.parentWells === {} || !this.tagLayout) {
          return this.parentWells ? { ...this.parentWells } : {}
        }

        let cw = {}

        Object.keys(this.tagLayout).forEach((wellName) => {
          cw[wellName] = { ...this.parentWells[wellName]}
          let tagIndx = 'X'
          if(this.tagLayout[wellName] > 0) {
            const origTagId = this.tagLayout[wellName]
            tagIndx = origTagId.toString()
            // check for tag substitution
            if((Object.keys(this.tagSubstitutions).length > 0) && (this.tagSubstitutions.hasOwnProperty(origTagId))) {
              tagIndx = this.tagSubstitutions[origTagId].toString()
            }
          }
          cw[wellName]['tagIndex'] = tagIndx
        })

        return cw
      },
      tag1GroupOptions() {
        this.tagGroupsList

        let options = []

        if(this.tagGroupsList && Object.keys(this.tagGroupsList).length > 0) {
          options = this.coreTagGroupOptions().slice()
          options.unshift({ value: null, text: 'Please select an i7 Tag 1 group...' })
        }

        return options
      },
      tag2GroupOptions() {
        this.tagGroupsList

        let options = []

        if(this.tagGroupsList && Object.keys(this.tagGroupsList).length > 0) {
          options = this.coreTagGroupOptions().slice()
          options.unshift({ value: null, text: 'Please select an i5 Tag 2 group...' })
        }

        return options
      },
      numberOfTags() {
        this.tagGroupsList
        this.tag1GroupId
        this.tag2GroupId
        this.tag1GroupTags
        this.tag2GroupTags

        let numTags = 0

        if(this.tagGroupsList && Object.keys(this.tagGroupsList).length > 0) {
          if(this.tag1GroupId) {
            numTags = this.tag1GroupTags.length
          } else if(this.tag2GroupId) {
            numTags = this.tag2GroupTags.length
          }
        }

        return numTags
      },
      numberOfTargetWells() {
        let numTargets = 0

        if(this.parentWells) {
          if(this.walkingBy === 'manual by plate') {
            numTargets = this.calcNumTagsForSeqPlate()
          } else if(this.walkingBy === 'wells of plate') {
            numTargets = Object.keys(this.parentWells).length
          } else if(this.walkingBy === 'manual by pool') {
            numTargets = this.calcNumTagsForPooledPlate()
          } else if(this.walkingBy === 'as group by plate') {
            numTargets = this.calcNumTagsForGroupByPlate()
          }
        }
        return numTargets
      },
      wellModalTitle() {
        this.wellModalDetails
        return ((this.wellModalDetails.wellName) ? 'Well: ' + this.wellModalDetails.wellName : '')
      },
      substituteTagState() {
        this.tagMapIds
        this.substituteTagId

        if(!this.tagMapIds) { return false }
        return (this.tagMapIds.includes(Number.parseInt(this.substituteTagId)) ? true : false)
      },
      substituteTagValidFeedback() {
        return (this.substituteTagState === true ? 'Valid' : '')
      },
      substituteTagInvalidFeedback() {
        return ((!this.substituteTagState) ? 'Number does not match a tag map id' : '')
      },
      buttonText() {
        return {
            'setup': 'Set up plate tag layout...',
            'pending': 'Create new Custom Tagged plate in Sequencescape',
            'busy': 'Sending...',
            'success': 'Custom Tagged plate successfully created',
            'failure': 'Failed to create Custom Tagged plate, retry?'
        }[this.createButtonState]
      },
      buttonStyle() {
        return {
          'setup': 'danger',
          'pending': 'primary',
          'busy': 'outline-primary',
          'success': 'success',
          'failure': 'danger'
        }[this.createButtonState]
      },
      buttonDisabled() {
        return {
          'setup': true,
          'pending': false,
          'busy': true,
          'success': true,
          'failure': false
        }[this.createButtonState]
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
