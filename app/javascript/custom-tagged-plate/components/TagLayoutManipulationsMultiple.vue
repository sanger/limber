<template>
  <b-container fluid>
    <lb-tag-groups-lookup
      :api="api"
      @change="tagGroupsLookupUpdated"
    />
    <b-row class="form-group form-row">
      <b-col>
        <b-form-group
          id="tag1_group_selection_group"
          horizontal
          label="i7 Tag 1 Group:"
          label-for="tag1_group_selection"
        >
          <b-form-select
            id="tag1_group_selection"
            v-model="tag1GroupId"
            :options="tag1GroupOptions"
            @change="tagGroupChanged"
            @input="updateTagParams"
          />
        </b-form-group>
      </b-col>
    </b-row>
    <b-row class="form-group form-row">
      <b-col>
        <!-- TODO label with one option -->
        <b-form-group
          id="walking_by_label_group"
          label="Walking By Option:"
          label-for="walking_by_label"
        >
          <b-form-input
            id="walking_by_label"
            type="text"
            :value="walkingBy"
            :disabled="true"
          />
        </b-form-group>
      </b-col>
      <b-col>
        <b-form-group
          id="direction_options_group"
          label="Directions Options:"
          label-for="direction_options"
        >
          <b-form-select
            id="direction_options"
            v-model="direction"
            :options="directionOptions"
            @input="updateTagParams"
          />
        </b-form-group>
      </b-col>
    </b-row>
    <b-row class="form-group form-row">
      <b-col>
        <b-form-group
          id="offset_tags_by_group"
          label="Offset tags by:"
          label-for="offset_tags_by_input"
          :invalid-feedback="offsetTagsByInvalidFeedback"
          :valid-feedback="offsetTagsByValidFeedback"
          :state="offsetTagsByState"
        >
          <b-form-input
            id="offset_tags_by_input"
            v-model="offsetTagsBy"
            type="number"
            :min="offsetTagsByMin"
            :max="offsetTagsByMax"
            step="1"
            :placeholder="offsetTagsByPlaceholder"
            :state="offsetTagsByState"
            :disabled="offsetTagsByDisabled"
            @input="updateTagParams"
          />
        </b-form-group>
      </b-col>
      <b-col>
        <b-form-group
          id="tags_per_well_group"
          label="Tags per well:"
          label-for="tags_per_well"
        >
          <b-form-input
            id="tags_per_well"
            type="number"
            :value="tagsPerWell"
            :disabled="true"
          />
        </b-form-group>
      </b-col>
    </b-row>
  </b-container>
</template>

<script>
import TagGroupsLookup from 'shared/components/TagGroupsLookup.vue'

/**
 * Allows the user to select tags and arrange their layout on the plate.
 * This version is for plates that contain multiple tags per well e.g. for
 * Chromium plates.
 * They manually select a tag group, then select various options to change
 * how the tags are laid out on the plate.
 * It provides:
 * - Select dropdown for manual selection of tag groups 1
 * - Select dropdown for direction choices for how the tags on the plate are
 * laid out
 * - An offset tags by input field for offsetting the layout by a number
 * - Any change emits all modifiable elements to the parent for recalculation
 * of the tag layout.
 */
export default {
  name: 'TagLayoutManipulationsMultiple',
  components: {
    'lb-tag-groups-lookup': TagGroupsLookup
  },
  props: {
    // A devour API object. eg. new devourClient(apiOptions)
    // Passed through to the tag groups lookup and tag plate scan child
    // components.
    api: {
      type: Object,
      required: true
    },
    // The current number of useable tags, calculated by the parent component
    // and used to determine tag offset limits.
    numberOfTags: {
      type: Number,
      default: () => { return 0 }
    },
    // The number of target wells, calculated by the parent component and
    // used to determine the tag offset limits.
    numberOfTargetWells: {
      type: Number,
      default: () => { return 0 }
    },
    // The tags per well number, determined by the plate purpose and used here
    // to determine what tag layout walking by options are available.
    tagsPerWell: {
      type: Number,
      default: () => { return 1 }
    },
  },
  data () {
    return {
      tagGroupsList: {}, // holds the list of tag groups once retrieved
      tag1GroupId: null, // holds the id of tag group 1 once selected
      walkingBy: 'as group by plate', // holds the chosen tag layout walking by option
      direction: 'column', // holds the chosen tag layout direction option
      offsetTagsByMin: 0, // holds the tag offset minimum value
      offsetTagsBy: 0, // holds the entered tag offset number
      nullTagGroup: { // null tag group object used in place of a selected tag group
        uuid: null, // uuid of the tag group
        name: 'No tag group selected', // name of the tag group
        tags: [] // array of tags in the tag group
      }
    }
  },
  computed: {
    directionOptions() {
      return [
        { value: null, text: 'Please select a Direction Option...' },
        { value: 'row', text: 'By Rows' },
        { value: 'column', text: 'By Columns' },
        { value: 'inverse row', text: 'By Inverse Rows' },
        { value: 'inverse column', text: 'By Inverse Columns' }
      ]
    },
    offsetTagsByMax() {
      if(this.numberOfTags === 0 || this.numberOfTargetWells === 0) {
        return null
      }
      return this.numberOfTags - this.numberOfTargetWells
    },
    offsetTagsByDisabled() {
      return (!this.offsetTagsByMax || this.offsetTagsByMax <= 0)
    },
    offsetTagsByPlaceholder() {
      let placeholder = 'Enter offset number...'

      if(this.numberOfTags === 0) {
        placeholder = 'Select tags first...'
      } else if(this.numberOfTargetWells === 0) {
        placeholder = 'No target wells...'
      } else if(this.offsetTagsByMax < 0) {
        placeholder = 'Not enough tags...'
      } else if(this.offsetTagsByMax === 0) {
        placeholder = 'No spare tags...'
      }

      return placeholder
    },
    isOffsetTagsByMaxValid() {
      return (this.offsetTagsByMax && this.offsetTagsByMax > 0)
    },
    offsetTagsByState() {
      return (this.isOffsetTagsByMaxValid) ? this.isOffsetTagsByWithinLimits : null
    },
    isOffsetTagsByWithinLimits() {
      return ((this.offsetTagsBy >= this.offsetTagsByMin) &&
              (this.offsetTagsBy <= this.offsetTagsByMax)) ? true : false
    },
    offsetTagsByInvalidFeedback() {
      if(this.isOffsetTagsByMaxValid) {
        let isChkLow = this.offsetTagsByCheckTooLow
        if(!isChkLow.valid) {
          return isChkLow.message
        }

        let isChkHigh = this.offsetTagsByCheckTooHigh
        if(!isChkHigh.valid) {
          return isChkHigh.message
        }
      }

      return ''
    },
    offsetTagsByCheckTooLow() {
      let ret = { valid: true, message: '' }

      if(this.offsetTagsBy < this.offsetTagsByMin) {
        ret.valid = false
        ret.message = 'Offset must be greater than or equal to ' + this.offsetTagsByMin
      }

      return ret
    },
    offsetTagsByCheckTooHigh() {
      let ret = { valid: true, message: '' }

      if(this.offsetTagsBy > this.offsetTagsByMax) {
        ret.valid = false
        ret.message = 'Offset must be less than or equal to ' + this.offsetTagsByMax
      }

      return ret
    },
    offsetTagsByValidFeedback() {
      return this.offsetTagsByState ? 'Valid' : ''
    },
    tag1Group() {
      return this.tagGroupsList[this.tag1GroupId] || this.nullTagGroup
    },
    coreTagGroupOptions() {
      return Object.values(this.tagGroupsList).map(tagGroup => {
        return { value: tagGroup.id, text: tagGroup.name }
      })
    },
    tag1GroupOptions() {
      return [{ value: null, text: 'Please select an i7 Tag 1 group...' }].concat(this.coreTagGroupOptions.slice())
    }
  },
  methods: {
    tagGroupsLookupUpdated(data) {
      if(!data || data.state === 'searching') {
        return
      } else if(data.state === 'valid') {
        this.tagGroupsList = { ...data.tagGroupsList }
      } else {
        console.log('Tag Groups lookup error: ', data['state'])
      }
    },
    extractTagGroupIds(plate) {
      this.offsetTagsBy = 0

      if(plate.lot.tag_layout_template.tag_group.id) {
        this.tag1GroupId = plate.lot.tag_layout_template.tag_group.id
      } else {
        this.tag1GroupId = null
      }
    },
    tagGroupChanged() {
      this.offsetTagsBy = 0
    },
    updateTagParams(_value) {
      const updatedData = {
        tagPlate: null,
        tag1Group: this.tag1Group,
        tag2Group: this.nullTagGroup,
        walkingBy: this.walkingBy,
        direction: this.direction,
        offsetTagsBy: Number.parseInt(this.offsetTagsBy)
      }

      this.$emit('tagparamsupdated', updatedData)
    }
  }
}

</script>

<style>
  input:invalid+span:after {
    content: '✖';
    padding-left: 5px;
  }

  input:valid+span:after {
    content: '✓';
    padding-left: 5px;
  }
</style>
