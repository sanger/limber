<template>
  <b-container fluid>
    <lb-tag-sets-lookup
      :api="api"
      resource-name="tag_set"
      :filter="tagSetFilter"
      includes="tag_group,tag2_group"
      @change="tagSetsLookupUpdated"
    />
    <dl v-if="ultimaApplications.length" id="ultima-applications" class="mb-3">
      <dt>{{ ultimaApplications.length === 1 ? 'Application' : 'Applications' }}</dt>
      <dd>
        <ul class="list-unstyled mb-0">
          <li v-for="application in ultimaApplications" :key="application">{{ application }}</li>
        </ul>
      </dd>
    </dl>
    <b-form-group label="Ultima Tag Set:" label-for="ultima_tag_set" class="mb-3">
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
    ultimaApplications: {
      type: Array,
      default: () => [],
    },
    tagSets: {
      type: Array,
      default: null,
    },
    tagGroupAdapterTypeNameFilter: {
      type: String,
      default: 'null',
    },
  },
  data() {
    return {
      // Fixed layout for the MVP (Y26-274): tags are in column order on the
      // tag plate. Consecutive tags go to the wells with samples, in column
      // order, starting from the offset.
      walkingBy: 'manual by plate',
      direction: 'column',
    }
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
      if (this.tagSets !== null) {
        return Object.values(this.tagSetList).find((tagSet) => tagSet.name === this.tagSetId) || this.nullTagSet
      }

      return this.tagSetList?.[this.tagSetId] || this.nullTagSet
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
  methods: {
    tagSetsLookupUpdated(data) {
      this.tagSetList = data.state === 'valid' && data.results ? data.results : {}
      if (this.tagSetId) {
        this.updateTagParams()
      }
    },
  },
}
</script>
