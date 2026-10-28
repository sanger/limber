<template>
  <b-container fluid>
    <lb-tag-sets-lookup
      :api="api"
      resource-name="tag_set"
      :filter="tagSetFilter"
      includes="tag_group,tag2_group"
      @change="tagSetsLookupUpdated"
    />
    <table v-if="ultimaApplications.length" id="ultima-applications" class="table table-sm mb-3">
      <thead>
        <tr>
          <th scope="col">Application</th>
          <th scope="col">UGA Primer</th>
          <th scope="col">UGB Primer</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="application in ultimaApplications" :key="application.name">
          <td>{{ application.name }}</td>
          <td>{{ application.uga_primer }}</td>
          <td>{{ application.ugb_primer }}</td>
        </tr>
      </tbody>
    </table>
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
    // The applications of the plate's requests, each with name, uga_primer
    // and ugb_primer, in the column order of the wells
    ultimaApplications: {
      type: Array,
      default: () => [],
    },
    allowedTagSetNames: {
      type: Array,
      default: null,
    },
    tagGroupAdapterTypeNameFilter: {
      type: String,
      default: null,
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
      const options = Object.values(this.tagSetList).map((tagSet) => ({ value: tagSet.id, text: tagSet.name }))
      if (this.allowedTagSetNames === null) {
        return options.sort((first, second) => first.text.localeCompare(second.text))
      }
      // Only the configured tag sets, in the configured order
      return this.allowedTagSetNames.flatMap((name) => options.filter((option) => option.text === name))
    },
    tagSetFilter() {
      if (this.tagGroupAdapterTypeNameFilter) {
        return { tag_group_adapter_type_name: this.tagGroupAdapterTypeNameFilter }
      }
      return {}
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
