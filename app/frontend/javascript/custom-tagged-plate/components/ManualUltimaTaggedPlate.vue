<template>
  <custom-tagged-plate v-bind="$attrs">
    <template #tag-layout-controls="controls">
      <manual-ultima-tag-layout
        :api="controls.api"
        :number-of-tags="controls.numberOfTags"
        :number-of-target-wells="controls.numberOfTargetWells"
        :tags-per-well="controls.tagsPerWell"
        :tag-group-adapter-type-name-filter="tagGroupAdapterTypeNameFilter"
        :allowed-tag-set-names="configuredAllowedTagSetNames"
        :ultima-applications="applicationNames"
        @tagparamsupdated="controls.updateTagParams"
      />
    </template>
  </custom-tagged-plate>
</template>

<script>
import CustomTaggedPlate from './CustomTaggedPlate.vue'
import ManualUltimaTagLayout from './ManualUltimaTagLayout.vue'

export default {
  name: 'ManualUltimaTaggedPlate',
  components: { CustomTaggedPlate, ManualUltimaTagLayout },
  inheritAttrs: false,
  props: {
    ultimaApplications: {
      type: String,
      default: '[]',
    },
    tagGroupAdapterTypeNameFilter: {
      type: String,
      default: 'null',
    },
    allowedTagSetNames: {
      type: String,
      default: 'null',
    },
  },
  computed: {
    applicationNames() {
      return JSON.parse(this.ultimaApplications)
    },
    configuredAllowedTagSetNames() {
      return JSON.parse(this.allowedTagSetNames)
    },
  },
}
</script>
