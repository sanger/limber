<template>
  <b-container fluid>
    <lb-tag-groups-lookup
      :api="api"
      resource-name="tag_group"
      :filter="tagGroupLookupFilter()"
      @change="tagGroupsLookupUpdated($event)"
    />
    <lb-tag-sets-lookup
      :api="api"
      resource-name="tag_set"
      :filter="tagGroupLookupFilter()"
      :includes="tagSetLookupIncludes"
      @change="tagSetsLookupUpdated($event)"
    />
    <b-row class="mb-3">
      <b-col>
        <b-form-group id="tag_plate_scan_group" label="Scan in the tag plate you wish to use here...">
          <lb-plate-scan
            id="tag_plate_scan"
            :api="api"
            :label="'Tag Plate'"
            labware-type="qcable"
            :scan-disabled="tagPlateScanDisabled"
            :includes="tagPlateLookupIncludes"
            :fields="tagPlateLookupFields"
            :validators="scanValidation"
            @change="tagPlateScanned($event)"
          />
        </b-form-group>
      </b-col>
    </b-row>
    <b-row class="mb-3">
      <b-col>
        <b-form-group id="tag_set_selection_group" horizontal label="Select Tag Set:" label-for="tag_set_selection">
          <b-form-select
            id="tag_set_selection"
            v-model="tagSetId"
            :options="tagSetOptions"
            :disabled="tagSetsDisabled"
            @update:model-value="tagGroupInput"
            @change="tagSetChanged"
          />
        </b-form-group>
      </b-col>
    </b-row>
    <b-row v-if="tag1GroupName">
      <b-col>
        <b-form-group id="tag1_name_label" label="i7 Tag 1 Group:" label-for="tag1_name">
          <b-form-input id="tag1_name" :model-value="tag1GroupName" :disabled="true" />
        </b-form-group>
      </b-col>
    </b-row>
    <b-row v-if="tag2GroupName">
      <b-col>
        <b-form-group id="tag2_name_label" label="i5 Tag 2 Group:" label-for="tag2_name">
          <b-form-input id="tag2_name" :model-value="tag2GroupName" :disabled="true" />
        </b-form-group>
      </b-col>
    </b-row>
    <b-row class="mb-3">
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
    <b-row class="mb-3">
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
import LabwareScan from '@/javascript/shared/components/LabwareScan.vue'
import { checkState, checkQCableWalkingBy } from '@/javascript/shared/components/plateScanValidators.js'
import TagLayout from '@/javascript/custom-tagged-plate/components/mixins/TagLayout.js'

/**
 * Allows the user to select tags and arrange their layout on the plate.
 * They can either scan a tag plate or manually select one or two (if dual
 * indexed) tag groups, then select various options to change how the tags
 * are laid out on the plate.
 * It provides:
 * - A tag plate scan input field
 * - Select dropdowns for manual selection of tag groups 1 and 2
 * - Select dropdowns for walking by and direction choices for how the tags on
 * the plate are laid out
 * - An offset tags by input field for offsetting the layout by a number
 * - Any change emits all modifiable elements to the parent for recalculation
 * of the tag layout.
 */
export default {
  name: 'TagLayoutManipulations',
  components: {
    'lb-plate-scan': LabwareScan,
  },
  mixins: [TagLayout],
  props: {
    tagGroupAdapterTypeNameFilter: {
      // filters list of tag groups if present
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      tagPlateWasScanned: false, // flag to indicate a tag plate was scanned
      tagPlateScanDisabled: false, // flag to indicate the plate scan was disabled
      walkingBy: 'wells of plate', // holds the chosen tag layout walking by option
    }
  },
  computed: {
    scanValidation() {
      return [checkState(['available', 'exhausted']), checkQCableWalkingBy(['wells of plate'])]
    },
    tagPlateLookupFields() {
      return {
        assets: 'uuid',
        lots: 'uuid,tag_layout_template',
        tag_layout_templates: 'uuid,tag_group,tag2_group,direction,walking_by',
        tag_groups: 'uuid,name,tags',
      }
    },
    tagPlateLookupIncludes() {
      return 'asset,lot,lot.tag_layout_template,lot.tag_layout_template.tag_group,lot.tag_layout_template.tag2_group'
    },
    tagSetLookupIncludes() {
      return 'tag_group,tag2_group'
    },
    tagSetsDisabled() {
      return typeof this.tagPlate != 'undefined' && this.tagPlate !== null
    },
    walkingByOptions() {
      return [
        { value: null, text: 'Please select a by Walking By Option...' },
        { value: 'manual by pool', text: 'By Pool' },
        { value: 'manual by plate', text: 'By Plate (Sequential)' },
        { value: 'wells of plate', text: 'By Plate (Fixed)' },
      ]
    },
    tag1GroupName() {
      return this.tag1Group?.name === this.nullTagGroup.name ? null : this.tag1Group?.name
    },
    tag2GroupName() {
      return this.tag2Group?.name === this.nullTagGroup.name ? null : this.tag2Group?.name
    },
  },
  methods: {
    emptyTagPlate() {
      this.tagPlate = null
      this.tag1GroupId = null
      this.tag2GroupId = null
      this.updateTagPlateScanDisabled()
    },
    extractTagGroupIds(plate) {
      this.tagPlate = plate
      this.tagPlateWasScanned = true
      this.tag1GroupId = null
      this.tag2GroupId = null

      if (plate.lot && plate.lot.tag_layout_template) {
        if (plate.lot.tag_layout_template.tag_group && plate.lot.tag_layout_template.tag_group.id) {
          this.tag1GroupId = plate.lot.tag_layout_template.tag_group.id
        }
        if (plate.lot.tag_layout_template.tag2_group && plate.lot.tag_layout_template.tag2_group.id) {
          this.tag2GroupId = plate.lot.tag_layout_template.tag2_group.id
        }
      }

      this.updateTagPlateScanDisabled()
    },

    tagGroupChanged() {
      this.tagPlateWasScanned = false
    },
    tagGroupInput() {
      this.updateTagPlateScanDisabled()
    },

    tagSetInput() {
      this.updateTagPlateScanDisabled()
    },
    tagSetChanged() {
      this.tagPlateWasScanned = false
      this.tag1GroupId = this.selectedTagSet?.tag_group?.id
      this.tag2GroupId = this.selectedTagSet?.tag2_group?.id
      this.updateTagPlateScanDisabled()
    },

    tagPlateScanned(data) {
      if (data) {
        if (data.state === 'valid' && data.plate) {
          this.extractTagGroupIds(data.plate)
        } else if (data.state === 'empty') {
          this.emptyTagPlate()
        }
      }
    },
    updateTagPlateScanDisabled() {
      if (this.tagPlateWasScanned) {
        this.tagPlateScanDisabled = false
      } else {
        if (this.tag1GroupId || this.tag2GroupId) {
          this.tagPlateScanDisabled = true
        } else {
          this.tagPlateScanDisabled = false
        }
      }
      this.updateTagParams()
    },
    tagGroupLookupFilter() {
      if (this.tagGroupAdapterTypeNameFilter) {
        return {
          tag_group_adapter_type_name: this.tagGroupAdapterTypeNameFilter,
        }
      }
      return {}
    },
  },
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
