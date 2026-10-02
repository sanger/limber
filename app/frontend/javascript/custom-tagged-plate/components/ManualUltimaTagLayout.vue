<template>
  <b-container fluid>
    <lb-tag-sets-lookup
      :api="api"
      resource-name="tag_set"
      :filter="tagSetFilter"
      includes="tag_group,tag2_group"
      @change="tagSetsLookupUpdated"
    />
    <b-form-group label="Ultima tag set" label-for="ultima_tag_set" class="mb-3">
      <b-form-select
        id="ultima_tag_set"
        v-model="tagSetId"
        :options="tagSetOptions"
        @update:model-value="updateTagParams"
      />
    </b-form-group>
    <dl v-if="tagSetId" class="small">
      <dt>Tag group</dt>
      <dd>{{ tag1Group.name }}</dd>
      <template v-if="tag2Group.uuid">
        <dt>Second tag group</dt>
        <dd>{{ tag2Group.name }}</dd>
      </template>
    </dl>
    <b-form-group label="Layout" label-for="ultima_walking_by" class="mb-3">
      <b-form-select
        id="ultima_walking_by"
        v-model="walkingBy"
        :options="walkingByOptions"
        @update:model-value="updateTagParams"
      />
    </b-form-group>
    <b-form-group label="Direction" label-for="ultima_direction" class="mb-3">
      <b-form-select
        id="ultima_direction"
        v-model="direction"
        :options="directionOptions"
        @update:model-value="updateTagParams"
      />
    </b-form-group>
    <lb-tag-offset
      :number-of-tags="numberOfTags"
      :number-of-target-wells="numberOfTargetWells"
      :tags-per-well="tagsPerWell"
      @tagoffsetchanged="tagOffsetChanged"
    />
  </b-container>
</template>

<script>
import TagLayout from './mixins/TagLayout.js'

export default {
  name: 'ManualUltimaTagLayout',
  mixins: [TagLayout],
  props: {
    tagGroupAdapterTypeNameFilter: {
      type: String,
      default: 'Ultima',
    },
  },
  data() {
    return {
      walkingBy: 'manual by plate',
    }
  },
  computed: {
    tagSetFilter() {
      return { tag_group_adapter_type_name: this.tagGroupAdapterTypeNameFilter }
    },
    tag1Group() {
      return this.selectedTagSet.tag_group || this.nullTagGroup
    },
    tag2Group() {
      return this.selectedTagSet.tag2_group || this.nullTagGroup
    },
    walkingByOptions() {
      return [
        { value: 'manual by plate', text: 'By Plate (Sequential)' },
        { value: 'manual by pool', text: 'By Pool' },
        { value: 'wells of plate', text: 'By Plate (Fixed)' },
      ]
    },
  },
}
</script>