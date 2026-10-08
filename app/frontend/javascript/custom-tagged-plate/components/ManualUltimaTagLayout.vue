<template>
  <b-container fluid>
    <lb-tag-sets-lookup
      v-if="tagSets === null"
      :api="api"
      resource-name="tag_set"
      :filter="tagSetFilter"
      includes="tag_group,tag2_group"
      @change="tagSetsLookupUpdated"
    />
    <b-form-group label="Ultima Tag Set" label-for="ultima_tag_set" class="mb-3">
      <b-form-select
        id="ultima_tag_set"
        v-model="tagSetId"
        :options="tagSetOptions"
        @update:model-value="updateTagParams"
      />
    </b-form-group>
    <dl v-if="tag1Group.uuid" class="small">
      <dt>Tag group</dt>
      <dd>{{ tag1Group.name }}</dd>
      <template v-if="tag2Group.uuid">
        <dt>Second tag group</dt>
        <dd>{{ tag2Group.name }}</dd>
      </template>
    </dl>

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
    tagSets: {
      type: Array,
      default: null,
    },
    tagGroupAdapterTypeNameFilter: {
      type: String,
      default: 'Ultima',
    },
  },
  computed: {
    coreTagSetOptions() {
      if (this.tagSets !== null) {
        return this.tagSets.map((name) => ({ value: name, text: name }))
      }

      return Object.values(this.tagSetList)
        .map((tagSet) => ({ value: tagSet.id, text: tagSet.name }))
        .sort((first, second) => first.text.localeCompare(second.text))
    },
    selectedTagSet() {
      return this.tagSets === null ? this.tagSetList?.[this.tagSetId] || this.nullTagSet : this.nullTagSet
    },
    tagSetFilter() {
      return { tag_group_adapter_type_name: this.tagGroupAdapterTypeNameFilter }
    },
    tag1Group() {
      return this.selectedTagSet.tag_group || this.nullTagGroup
    },
    tag2Group() {
      return this.selectedTagSet.tag2_group || this.nullTagGroup
    },
  },
}
</script>
