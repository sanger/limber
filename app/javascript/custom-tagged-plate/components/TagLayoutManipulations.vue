<template>
  <b-container fluid>
    <lb-tag-groups-lookup
      :api="api"
      @change="tagGroupsLookupUpdated"
    />
    <b-row class="form-group form-row">
      <b-col>
        <b-form-group
          id="tag_plate_scan_group"
          label="Scan in the tag plate you wish to use here..."
        >
          <lb-plate-scan
            id="tag_plate_scan"
            :api="api"
            :label="'Tag Plate'"
            :plate-type="'qcable'"
            :scan-disabled="tagPlateScanDisabled"
            includes="asset,lot,lot.tag_layout_template,lot.tag_layout_template.tag_group,lot.tag_layout_template.tag2_group"
            :fields="{ assets: 'uuid',
                       lots: 'uuid,tag_layout_template',
                       tag_layout_templates: 'uuid,tag_group,tag2_group,direction,walking_by',
                       tag_groups: 'uuid,name,tags' }"
            :validation="scanValidation()"
            @change="tagPlateScanned($event)"
          />
        </b-form-group>
      </b-col>
    </b-row>
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
            :disabled="tagGroupsDisabled"
            @input="tagGroupInput"
            @change="tagGroupChanged"
          />
        </b-form-group>
      </b-col>
    </b-row>
    <b-row class="form-group form-row">
      <b-col>
        <b-form-group
          id="tag2_group_selection_group"
          horizontal
          label="i5 Tag 2 Group:"
          label-for="tag2_group_selection"
        >
          <b-form-select
            id="tag2_group_selection"
            v-model="tag2GroupId"
            :options="tag2GroupOptions"
            :disabled="tagGroupsDisabled"
            @input="tagGroupInput"
            @change="tagGroupChanged"
          />
        </b-form-group>
      </b-col>
    </b-row>
    <b-row class="form-group form-row">
      <b-col>
        <b-form-group
          id="walking_by_options_group"
          label="Walking By Options:"
          label-for="walking_by_options"
        >
          <b-form-select
            id="walking_by_options"
            v-model="walkingBy"
            :options="walkingByOptions"
            @input="updateTagParams"
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
import PlateScan from 'shared/components/PlateScan'
import { checkState, checkQCableWalkingBy, aggregate } from 'shared/components/plateScanValidators'
import TagLayout from 'custom-tagged-plate/components/mixins/TagLayout'

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
    'lb-plate-scan': PlateScan
  },
  mixins: [TagLayout],
  data () {
    return {
      tagPlateWasScanned: false, // flag to indicate a tag plate was scanned
      tagPlateScanDisabled: false, // flag to indicate the plate scan was disabled
      walkingBy: 'manual by plate', // holds the chosen tag layout walking by option
    }
  },
  computed: {
    walkingByOptions() {
      return [
        { value: null, text: 'Please select a by Walking By Option...' },
        { value: 'manual by pool', text: 'By Pool' },
        { value: 'manual by plate', text: 'By Plate (Sequential)' },
        { value: 'wells of plate', text: 'By Plate (Fixed)' }
      ]
    },
    tagGroupsDisabled() {
      return (typeof this.tagPlate != 'undefined' && this.tagPlate !== null)
    },
    scanValidation() {
      return () => {
        return aggregate(checkState(['available','exhausted']), checkQCableWalkingBy(['wells of plate']))
      }
    }
  },
  methods: {
    updateTagPlateScanDisabled() {
      if(this.tagPlateWasScanned) {
        this.tagPlateScanDisabled = false
      } else {
        if(this.tag1GroupId || this.tag2GroupId) {
          this.tagPlateScanDisabled = true
        } else {
          this.tagPlateScanDisabled = false
        }
      }
      this.updateTagParams(null)
    },
    tagPlateScanned(data) {
      if(data && (data.state === 'valid') && data.plate) {
        this.extractTagGroupIds(data.plate)
      } else if(data.state === 'empty' && !data.plate) {
        this.emptyTagPlate()
      }
    },
    extractTagGroupIds(plate) {
      this.tagPlate = { ...plate }
      this.tagPlateWasScanned = true

      if(plate.lot.tag_layout_template.tag_group.id) {
        this.tag1GroupId = plate.lot.tag_layout_template.tag_group.id
      } else {
        this.tag1GroupId = null
      }

      if(plate.lot.tag_layout_template.tag2_group.id) {
        this.tag2GroupId = plate.lot.tag_layout_template.tag2_group.id
      } else {
        this.tag2GroupId = null
      }

      this.updateTagPlateScanDisabled()
    },
    emptyTagPlate() {
      this.tagPlate = null
      this.tag1GroupId = null
      this.tag2GroupId = null
      this.updateTagPlateScanDisabled()
    },
    tagGroupChanged() {
      this.tagPlateWasScanned = false
    },
    tagGroupInput() {
      this.updateTagPlateScanDisabled()
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
