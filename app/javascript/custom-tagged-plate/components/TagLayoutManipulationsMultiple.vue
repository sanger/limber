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
            :value="walkingByDisplayed"
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
        <lb-tag-offset
          id="tag_offset_input"
          ref="offsetTagsByComponent"
          :number-of-tags="numberOfTags"
          :number-of-target-wells="numberOfTargetWells"
          :tags-per-well="tagsPerWell"
          @tagoffsetchanged="tagOffsetChanged"
        />
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
import TagOffset from './TagOffset.vue'

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
    'lb-tag-groups-lookup': TagGroupsLookup,
    'lb-tag-offset': TagOffset
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
    },
    walkingByDisplayed() {
      return (this.walkingBy === 'as group by plate') ? 'Apply Multiple Tags' : this.walkingBy
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
    tagOffsetChanged(tagOffset) {
      this.offsetTagsBy = tagOffset
      this.updateTagParams(null)
    },
    updateTagParams(_value) {
      const updatedData = {
        tagPlate: null,
        tag1Group: this.tag1Group,
        tag2Group: this.nullTagGroup,
        walkingBy: this.walkingBy,
        direction: this.direction,
        offsetTagsBy: this.offsetTagsBy
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
