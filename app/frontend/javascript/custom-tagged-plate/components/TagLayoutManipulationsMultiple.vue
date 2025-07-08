<template>
  <b-container fluid>
    <lb-tag-groups-lookup :api="api" resource-name="tag_group" @change="tagGroupsLookupUpdated" />
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
            @update:model-value="updateTagParams"
          />
        </b-form-group>
      </b-col>
    </b-row>
    <b-row class="form-group form-row">
      <b-col>
        <b-form-group id="walking_by_options_group" label="Walking By Options:" label-for="walking_by_options">
          <b-form-select
            id="walking_by_options"
            v-model="walkingBy"
            :options="walkingByOptions"
            @update:model-value="updateTagParams"
          />
        </b-form-group>
      </b-col>
      <b-col>
        <b-form-group id="direction_options_group" label="Directions Options:" label-for="direction_options">
          <b-form-select
            id="direction_options"
            v-model="direction"
            :options="directionOptions"
            @update:model-value="updateTagParams"
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
        <b-form-group id="tags_per_well_group" label="Tags per well:" label-for="tags_per_well">
          <b-form-input id="tags_per_well" type="number" :model-value="tagsPerWell" :disabled="true" />
        </b-form-group>
      </b-col>
    </b-row>
  </b-container>
</template>

<script>
import TagLayout from '@/javascript/custom-tagged-plate/components/mixins/TagLayout.js'

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
  mixins: [TagLayout],
  data() {
    return {
      walkingBy: 'as fixed group by plate', // holds the chosen tag layout walking by option
    }
  },
  computed: {
    walkingByOptions() {
      return [
        { value: null, text: 'Please select a by Walking By Option...' },
        {
          value: 'as group by plate',
          text: 'Apply Multiple Tags (Sequential)',
        },
        {
          value: 'as fixed group by plate',
          text: 'Apply Multiple Tags (Fixed)',
        },
      ]
    },
  },
  methods: {},
}
</script>

<style scoped>
input:invalid + span:after {
  content: '✖';
  padding-left: '5px';
}

input:valid + span:after {
  content: '✓';
  padding-left: '5px';
}
</style>
