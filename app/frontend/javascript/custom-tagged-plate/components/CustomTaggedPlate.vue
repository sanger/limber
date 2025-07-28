<template>
  <lb-page>
    <lb-loading-modal v-if="loading" :message="progressMessage" />
    <lb-main-content v-if="parentPlate">
      <div class="card-body mb-2">
        <h2 id="plate-title" class="card-title">
          {{ childPurposeName }}
          <span class="state-badge pending">Pending</span>
        </h2>
      </div>
      <lb-parent-plate-view
        :caption="plateViewCaption"
        :rows="numberOfRows"
        :columns="numberOfColumns"
        :wells="childWells"
        @onwellclicked="onWellClicked"
      />
      <lb-well-modal
        ref="wellModalCompRef"
        :well-modal-details="wellModalDetails"
        @wellmodalsubtituteselected="wellModalSubtituteSelected"
      />
      <lb-tag-substitution-details
        :tag-substitutions="tagSubstitutions"
        :tag-substitutions-allowed="tagSubstitutionsAllowed"
        @removetagsubstitution="removeTagSubstitution"
      />
    </lb-main-content>
    <lb-main-content v-else>
      <lb-parent-plate-lookup
        :api="devourApi"
        resource-name="plate"
        :includes="parentPlateLookupIncludes"
        :fields="parentPlateLookupFields"
        :filter="parentPlateLookupFilter"
        @change="parentPlateLookupUpdated"
      />
    </lb-main-content>
    <lb-sidebar>
      <b-container fluid>
        <b-row>
          <b-col>
            <lb-tag-layout-manipulations-multiple
              v-if="isMultipleTaggedPlate"
              :api="devourApi"
              :number-of-tags="numberOfTags"
              :number-of-target-wells="numberOfTargetWells"
              :tags-per-well="tagsPerWellAsNumber"
              @tagparamsupdated="tagParamsUpdated"
            />
            <lb-tag-layout-manipulations
              v-else
              :api="devourApi"
              :number-of-tags="numberOfTags"
              :number-of-target-wells="numberOfTargetWells"
              :tags-per-well="tagsPerWellAsNumber"
              :tag-group-adapter-type-name-filter="tagGroupAdapterTypeNameFilter"
              @tagparamsupdated="tagParamsUpdated"
            />
            <div class="form-group form-row d-grid">
              <b-button
                id="custom_tagged_plate_submit_button"
                name="custom_tagged_plate_submit_button"
                :disabled="createButtonDisabled"
                :variant="createButtonStyle"
                size="lg"
                @click="createPlate"
              >
                {{ createButtonText }}
              </b-button>
            </div>
          </b-col>
        </b-row>
      </b-container>
    </lb-sidebar>
  </lb-page>
</template>

<script>
import {
  extractChildUsedOligos,
  extractParentUsedOligos,
  extractParentWellSubmissionDetails,
} from '@/javascript/custom-tagged-plate/tagClashFunctions'
import { calculateTagLayout } from '@/javascript/custom-tagged-plate/tagLayoutFunctions.js'
import AssetLookupByUuid from '@/javascript/shared/components/AssetLookupByUuid.vue'
import LoadingModal from '@/javascript/shared/components/LoadingModal.vue'
import Plate from '@/javascript/shared/components/Plate.vue'
import devourApi from '@/javascript/shared/devourApi.js'
import { handleFailedRequest } from '@/javascript/shared/requestHelpers.js'
import resources from '@/javascript/shared/resources.js'
import valueConverter from '@/javascript/shared/valueConverter.js'
import TagLayoutManipulations from './TagLayoutManipulations.vue'
import TagLayoutManipulationsMultiple from './TagLayoutManipulationsMultiple.vue'
import TagSubstitutionDetails from './TagSubstitutionDetails.vue'
import WellModal from './WellModal.vue'

/**
 * Provides a custom tagged plate setup view which allows a user to select and
 * visually layout tags on a plate before creating the resulting new plate in
 * sequencescape. It provides:
 * - An abstract plate view displaying tag locations
 * - A tag selection and manipulations panel
 * - A clickable well interface for tag substitution selections
 * - A tag substitutions list to detail and allow removal of substitutions
 * - A plate creation button with visibility and text dependant on layout state
 */
export default {
  name: 'CustomTaggedPlate',
  components: {
    'lb-loading-modal': LoadingModal,
    'lb-parent-plate-lookup': AssetLookupByUuid,
    'lb-parent-plate-view': Plate,
    'lb-tag-substitution-details': TagSubstitutionDetails,
    'lb-tag-layout-manipulations': TagLayoutManipulations,
    'lb-tag-layout-manipulations-multiple': TagLayoutManipulationsMultiple,
    'lb-well-modal': WellModal,
  },
  props: {
    sequencescapeApi: {
      // Sequencescape V2 API for creation of the custom tagged plate
      type: String,
      default: 'http://localhost:3000/api/v2',
    },
    sequencescapeApiKey: {
      // Sequencescape V2 API authentication key
      type: String,
      default: 'development',
    },
    purposeUuid: {
      // Plate purpose uuid for the custom tagged plate, used to identify which
      // plate creator should be used
      type: String,
      required: true,
    },
    purposeName: {
      // Plate purpose name for the custom tagged plate, used for display
      type: String,
      required: true,
    },
    targetUrl: {
      // URL of the child plate being created, to which the user will be
      // redirected after a successful plate creation. We use this rather than
      // relying on the server to redirect automatically.
      type: String,
      required: true,
    },
    parentUuid: {
      // The uuid of the parent plate, used to lookup the parent plate details
      // to build the abstract new plate to which the tags will be applied.
      type: String,
      required: true,
    },
    tagsPerWell: {
      // The tags per well number, derived from plate purpose and used to
      // indicate whether we are dealing with a normal or Chromium plate.
      type: String,
      required: true,
    },
    locationObj: {
      // This is used to mock the browser location bar for testing purposes.
      type: [Object, Location],
      default: () => {
        return location
      },
    },
    tagGroupAdapterTypeNameFilter: {
      // This is passed through to the tag groups lookup and filters that list if present
      type: String,
      required: false,
      default: null,
    },
    filters: {
      // This is passed through to the tag groups lookup and filters that list if present
      type: Object,
      required: false,
      default: () => {
        return {}
      },
    },
  },
  data() {
    return {
      loading: true, // tracks loading state for the page modal
      progressMessage: 'Fetching parent details...', // holds message displayed by page modal
      parentPlate: null, // the parent plate retrieved using the parentUuid prop
      devourApi: devourApi({ apiUrl: this.sequencescapeApi }, resources, this.sequencescapeApiKey), // devour API object
      plateViewCaption: 'Modify the tag layout for the new plate using options on the right', // caption for plate view
      creationRequestInProgress: null, // flag to indicate plate creation underway
      creationRequestSuccessful: null, // flag to indicate success of plate creation
      tagPlate: null, // scanned tag plate
      tag1Group: null, // selected tag 1 group
      tag2Group: null, // selected tag 2 group
      walkingBy: null, // tag layout walking by type
      direction: null, // tag layout direction type
      offsetTagsBy: null, // number to offset the tag layout by
      tagSubstitutions: {}, // tag substitutions required e.g. { 1:2, 5:8 }
      wellModalDetails: {
        // well modal details to be passed to the well modal child component
        position: '', // well position on plate e.g. A1
        originalTag: null, // original tag map id from layout
        tagMapIds: [], // allowed tag map ids for substitutions
        validity: { valid: false, message: 'default' }, // validity of this well
        existingSubstituteTagId: null, // current tag map id if the tag was already substituted
      },
    }
  },
  computed: {
    childPurposeName() {
      return this.purposeName
    },
    childWells() {
      this.tagLayout
      this.tagSubstitutions // used for tag substitution check
      this.childUsedOligos // used for tag clash check

      if (this.parentWells == {}) {
        return {}
      }
      if (Object.keys(this.tagLayout).length === 0) {
        return { ...this.parentWells }
      }

      let cw = {}
      Object.keys(this.tagLayout).forEach((position) => {
        cw[position] = { ...this.parentWells[position] }

        let tagMapIds = []
        if (this.tagLayout[position].length > 0) {
          cw[position]['validity'] = { valid: true, message: '' }

          const submId = cw[position]['submId']

          tagMapIds = this.tagLayout[position].slice(0)

          for (let i = 0; i < tagMapIds.length; i++) {
            if (tagMapIds[i] === -1) {
              cw[position]['validity'] = {
                valid: false,
                message: 'Missing tag ids for this well',
              }
            } else {
              tagMapIds[i] = this.checkTagForSubstitution(tagMapIds[i])
            }
          }

          if (cw[position]['validity'].valid === true) {
            cw[position]['validity'] = this.checkWellForTagClash(tagMapIds, submId, position)
          }
        }
        cw[position]['tagMapIds'] = tagMapIds
      })

      return cw
    },
    childUsedOligos() {
      return extractChildUsedOligos(
        this.parentUsedOligos,
        this.parentWellSubmissionDetails,
        this.tagLayout,
        this.tagSubstitutions,
        this.tagGroupOligoStrings,
      )
    },
    createButtonDisabled() {
      return {
        setup: true,
        pending: false,
        busy: true,
        success: true,
        failure: false,
      }[this.createButtonState]
    },
    createButtonState() {
      this.creationRequestInProgress
      this.creationRequestSuccessful

      if (!this.isChildWellsValid) {
        return 'setup'
      } else if (this.creationRequestInProgress === null) {
        return 'pending'
      } else if (this.creationRequestInProgress) {
        return 'busy'
      } else if (this.creationRequestSuccessful) {
        return 'success'
      } else {
        return 'failure'
      }
    },
    createButtonStyle() {
      return {
        setup: 'danger',
        pending: 'primary',
        busy: 'outline-primary',
        success: 'success',
        failure: 'danger',
      }[this.createButtonState]
    },
    createButtonText() {
      return {
        setup: 'Set up plate tag layout...',
        pending: 'Create new Custom Tagged plate',
        busy: 'Sending...',
        success: 'Custom Tagged plate successfully created',
        failure: 'Failed to create Custom Tagged plate, retry?',
      }[this.createButtonState]
    },
    isChildWellsValid() {
      if (Object.keys(this.childWells).length === 0) {
        return false
      }

      let invalidCount = 0
      Object.keys(this.childWells).forEach((position) => {
        if (this.childWells[position].aliquotCount > 0) {
          if (this.childWells[position].validity.valid === false) {
            invalidCount++
          }
        }
      })

      return invalidCount === 0 ? true : false
    },
    isMultipleTaggedPlate() {
      return this.tagsPerWellAsNumber > 1 ? true : false
    },
    numberOfColumns() {
      return this.parentPlate ? this.parentPlate.number_of_columns : null
    },
    numberOfRows() {
      return this.parentPlate ? this.parentPlate.number_of_rows : null
    },
    numberOfTag1GroupTags() {
      return this.tag1GroupTags.length
    },
    numberOfTag2GroupTags() {
      return this.tag2GroupTags.length
    },
    numberOfTags() {
      return this.useableTagMapIds.length
    },
    numberOfTargetWells() {
      let numTargets = 0

      if (this.parentWells) {
        if (this.walkingBy === 'manual by plate') {
          numTargets = this.calcNumTagsForSeqPlate()
        } else if (this.walkingBy === 'wells of plate') {
          numTargets = Object.keys(this.parentWells).length
        } else if (this.walkingBy === 'manual by pool') {
          numTargets = this.calcNumTagsForPooledPlate()
        } else if (this.walkingBy === 'as group by plate') {
          numTargets = this.calcNumTagsForGroupByPlate()
        }
      }
      return numTargets
    },
    parentPlateLookupIncludes() {
      return 'wells,wells.aliquots,wells.aliquots.request,wells.aliquots.request.submission,wells.requests_as_source,wells.requests_as_source.submission'
    },
    parentPlateLookupFields() {
      return {
        wells: 'uuid,position,aliquots,requests_as_source',
        aliquots: 'request',
        requests: 'uuid,submission',
        submissions: 'uuid,name,used_tags',
      }
    },
    parentPlateLookupFilter() {
      return { uuid: this.parentUuid }
    },
    parentWells() {
      if (!this.parentPlate) {
        return {}
      }

      let wells = {}

      this.parentPlate.wells.forEach((well) => {
        const position = well.position.name

        wells[position] = {
          position: position,
          aliquotCount: 0,
          validity: { valid: true, message: 'No aliquot in this well' },
        }

        if (well.aliquots && well.aliquots.length > 0) {
          wells[position]['aliquotCount'] = well.aliquots.length
          wells[position]['submId'] = this.parentWellSubmissionDetails[position]['subm_id']
          wells[position]['pool_index'] = this.parentWellSubmissionDetails[position]['pool_index']
          wells[position]['colour_index'] = this.parentWellSubmissionDetails[position]['pool_index']
          wells[position]['validity'] = {
            valid: false,
            message: 'Missing tag ids for this well',
          }
        }
      })

      return wells
    },
    parentWellData() {
      return Object.values(this.parentWells) || null
    },
    parentWellSubmissionDetails() {
      return extractParentWellSubmissionDetails(this.parentPlate)
    },
    parentUsedOligos() {
      return extractParentUsedOligos(this.parentPlate)
    },
    plateDims() {
      return {
        number_of_rows: this.numberOfRows,
        number_of_columns: this.numberOfColumns,
      }
    },
    tag1GroupMapIds() {
      return this.tag1GroupTags.map((a) => a.index)
    },
    tag1GroupTagOligos() {
      return this.tag1GroupTags.map((a) => a.oligo)
    },
    tag1GroupTags() {
      return this.tag1Group ? this.tag1Group.tags : []
    },
    tag1GroupUuid() {
      return this.tag1Group ? this.tag1Group.uuid : null
    },
    tag2GroupMapIds() {
      return this.tag2GroupTags.map((a) => a.index)
    },
    tag2GroupTagOligos() {
      return this.tag2GroupTags.map((a) => a.oligo)
    },
    tag2GroupTags() {
      return this.tag2Group ? this.tag2Group.tags : []
    },
    tag2GroupUuid() {
      return this.tag2Group ? this.tag2Group.uuid : null
    },
    tagGroupOligoStrings() {
      this.tag1GroupTags
      this.tag2GroupTags

      let tagOligoStrings = {}

      if (this.numberOfTag1GroupTags > 0) {
        if (this.numberOfTag2GroupTags > 0) {
          const numUseableTags = Math.min(this.numberOfTag1GroupTags, this.numberOfTag2GroupTags)
          for (let iBoth = 0; iBoth < numUseableTags; iBoth++) {
            const tg1 = this.tag1GroupTags[iBoth]
            const tg2 = this.tag2GroupTags[iBoth]
            tagOligoStrings[tg1.index] = tg1.oligo + ':' + tg2.oligo
          }
        } else {
          for (let i1 = 0; i1 < this.tag1GroupTags.length; i1++) {
            const tg = this.tag1GroupTags[i1]
            tagOligoStrings[tg.index] = tg.oligo
          }
        }
      } else if (this.numberOfTag2GroupTags > 0) {
        for (let i2 = 0; i2 < this.tag2GroupTags.length; i2++) {
          const tg = this.tag2GroupTags[i2]
          tagOligoStrings[tg.index] = tg.oligo
        }
      }

      return tagOligoStrings
    },
    tagLayout() {
      const inputData = {
        wells: this.parentWellData,
        plateDims: this.plateDims,
        tagMapIds: this.useableTagMapIds,
        walkingBy: this.walkingBy,
        direction: this.direction,
        offsetTagsBy: this.offsetTagsBy,
        tagsPerWell: this.tagsPerWell,
      }

      return calculateTagLayout(inputData)
    },
    tagsPerWellAsNumber() {
      return Number.parseInt(this.tagsPerWell) || null
    },
    tagSubstitutionsAllowed() {
      return !this.isMultipleTaggedPlate
    },
    useableTagMapIds() {
      let tags = []

      if (this.numberOfTag1GroupTags > 0) {
        if (this.numberOfTag2GroupTags > 0) {
          const numUseableTags = Math.min(this.numberOfTag1GroupTags, this.numberOfTag2GroupTags)
          tags = this.tag1GroupTags.slice(0, numUseableTags)
        } else {
          tags = this.tag1GroupTags
        }
      } else if (this.numberOfTag2GroupTags > 0) {
        tags = this.tag2GroupTags
      }

      const tagMapIds = tags.map((a) => a.index)

      return tagMapIds
    },
  },
  methods: {
    parentPlateLookupUpdated(data) {
      this.parentPlate = null
      if (data) {
        if (data.state === 'searching') {
          return
        } else {
          if (data.state === 'valid') {
            this.parentPlate = { ...data.results }
          } else {
            this.progressMessage = 'Parent plate lookup error: ' + data.state
          }
          this.loading = false
        }
      } else {
        this.progressMessage = 'Parent plate lookup error: nothing returned'
        this.loading = false
      }
    },
    tagParamsUpdated(updatedFormData) {
      this.tagPlate = updatedFormData.tagPlate
      this.tag1Group = updatedFormData.tag1Group
      this.tag2Group = updatedFormData.tag2Group
      this.walkingBy = updatedFormData.walkingBy
      this.direction = updatedFormData.direction
      this.offsetTagsBy = updatedFormData.offsetTagsBy
    },
    calcNumTagsForPooledPlate() {
      let poolTotals = {}

      Object.keys(this.parentWells).forEach((position) => {
        const poolIndex = this.parentWells[position].pool_index
        poolTotals[poolIndex] = poolTotals[poolIndex] + 1 || 1
      })

      return Math.max.apply(Math, Object.values(poolTotals))
    },
    calcNumTagsForSeqPlate() {
      let numTargets = 0

      Object.keys(this.parentWells).forEach((position) => {
        if (this.parentWells[position].aliquotCount > 0) {
          numTargets++
        }
      })

      return numTargets
    },
    calcNumTagsForGroupByPlate() {
      return this.calcNumTagsForSeqPlate()
    },
    checkTagForSubstitution(tagMapId) {
      if (Object.prototype.hasOwnProperty.call(this.tagSubstitutions, tagMapId)) {
        tagMapId = this.tagSubstitutions[tagMapId]
      }

      return tagMapId
    },
    checkWellForTagClash(tagMapIds, submId, position) {
      const str = tagMapIds.map((id) => this.tagGroupOligoStrings[id]).join(':')
      const arrayOligoLocns = this.childUsedOligos[submId][str]
      const filteredArrayOligoLocns = arrayOligoLocns.filter((locn) => locn !== position)

      if (filteredArrayOligoLocns.length > 0) {
        return {
          valid: false,
          message: 'Tag clash with the following: ' + filteredArrayOligoLocns.join(', '),
        }
      }

      return {
        valid: true,
        message: '',
      }
    },
    createPlate() {
      this.progressMessage = 'Creating plate...'
      this.loading = true
      this.creationRequestInProgress = true

      let payload = this.createPlatePayload()

      this.$axios({
        method: 'post',
        url: this.targetUrl,
        headers: { 'X-Requested-With': 'XMLHttpRequest' },
        data: payload,
      })
        .then((response) => {
          // Ajax responses automatically follow redirects, which
          // would result in us receiving the full HTML for the child
          // plate here, which we'd then need to inject into the
          // page, and update the history. Instead we don't redirect
          // application/json requests, and redirect the user ourselves.
          this.progressMessage = response.data.message
          this.locationObj.href = response.data.redirect // eslint-disable-line vue/no-mutating-props
          this.creationRequestInProgress = false
          this.creationRequestSuccessful = true
        })
        .catch((error) => {
          // Something has gone wrong
          // TODO Replace this with generic limber logging when available
          // See https://github.com/sanger/limber/issues/836
          handleFailedRequest(error)
          this.loading = false
          this.creationRequestInProgress = false
          this.creationRequestSuccessful = false
        })
    },
    createPlatePayload() {
      // initial tag is zero-based index of tag within its tag group, and is equal to
      // offset adjusted by the tags per well number
      const initialTag = this.offsetTagsBy * this.tagsPerWell
      // substitutions are strings e.g. { '1':'2','5':'8', etc }
      const subsStrngs = valueConverter(this.tagSubstitutions, (value) => value.toString())

      let payload = {
        plate: {
          purpose_uuid: this.purposeUuid,
          parent_uuid: this.parentUuid,
          filters: this.filters,
          tag_layout: {
            tag_group_uuid: this.tag1GroupUuid,
            tag2_group_uuid: this.tag2GroupUuid,
            direction: this.direction,
            walking_by: this.walkingBy,
            initial_tag: initialTag,
            substitutions: subsStrngs,
            tags_per_well: this.tagsPerWellAsNumber,
          },
          tag_plate: {
            asset_uuid: null,
            template_uuid: null,
            state: null,
          },
        },
      }

      // if the user scanned a tag plate
      if (this.tagPlate) {
        payload.plate.tag_plate = {
          asset_uuid: this.tagPlate.asset.uuid,
          template_uuid: this.tagPlate.lot.tag_layout_template.uuid,
          state: this.tagPlate.state,
        }
      }

      return payload
    },
    onWellClicked(position) {
      if (this.isWellValidForShowingModal(position)) {
        this.setUpWellModalDetails(position)
        this.showWellModal()
      }
    },
    isWellValidForShowingModal(position) {
      return this.isMultipleTaggedPlate || this.childWells[position].aliquotCount === 0 ? false : true
    },
    setUpWellModalDetails(position) {
      const originalTagMapId = this.tagLayout[position][0]

      this.wellModalDetails = {
        position: position,
        originalTag: originalTagMapId,
        tagMapIds: this.useableTagMapIds,
        validity: this.childWells[position].validity,
        existingSubstituteTagId: null,
      }

      // check if well tag already substituted and if so display that tag id
      if (originalTagMapId in this.tagSubstitutions) {
        this.wellModalDetails.existingSubstituteTagId = this.tagSubstitutions[originalTagMapId]
      }
    },
    showWellModal() {
      this.$refs.wellModalCompRef.show()
    },
    hideWellModal() {
      this.$refs.wellModalCompRef.hide()
    },
    wellModalSubtituteSelected(substituteTagId) {
      const originalTagMapId = this.wellModalDetails.originalTag

      if (originalTagMapId in this.tagSubstitutions && originalTagMapId === substituteTagId) {
        // because we have changed the tag id back to what it was originally,
        // delete the substitution from the list
        this.removeTagSubstitution(originalTagMapId)
      } else {
        this.tagSubstitutions[originalTagMapId] = substituteTagId
      }

      this.hideWellModal()
    },
    removeTagSubstitution(originalTagMapId) {
      delete this.tagSubstitutions[originalTagMapId]
    },
  },
}
</script>
