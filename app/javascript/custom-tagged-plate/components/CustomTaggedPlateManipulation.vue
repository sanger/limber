<template>
  <b-container fluid>
    <b-row class="form-group form-row">
      <b-col>
          <b-form-group id="tag_plate_scan_group"
                        label="Scan in the tag plate you wish to use here...">
            <!-- TODO scan plate, should in this case lookup a 'qcable' with barcode in a state of 'available' or 'exhausted' -->
            <!-- possible qcable states 'failed','passed','exhausted','destroyed','created','available','pending','qc_in_progress' -->
            <lb-plate-scan id="tag_plate_scan"
                           :api="api"
                           :label="'Tag Plate'"
                           :plateType="'qcable'"
                           :scanDisabled="tagPlateScanDisabled"
                           includes="lot,lot.tag_layout_template,lot.tag_layout_template.tag_group,lot.tag_layout_template.tag2_group"
                           :fields="{ lots: 'uuid,tag_layout_template',
                                      tag_layout_templates: 'uuid,tag_group,tag2_group,direction,walking_by',
                                      tag_groups: 'uuid,name,tags' }"
                           v-on:change="tagPlateScanned($event)">
            </lb-plate-scan>
        </b-form-group>
      </b-col>
    </b-row>
    <b-row class="form-group form-row">
      <b-col>
        <b-form-group id="tag1_group_selection_group"
                      horizontal
                      label="i7 Tag 1 Group:"
                      label-for="tag1_group_selection">
          <b-form-select id="tag1_group_selection"
                        :options="tag1GroupOptions"
                        v-model="tag1GroupId"
                        :disabled="tagGroupsDisabled"
                        @input="tagGroupInput"
                        @change="tagGroupChanged">
          </b-form-select>
         </b-form-group>
      </b-col>
    </b-row>
    <b-row class="form-group form-row">
      <b-col>
        <b-form-group id="tag2_group_selection_group"
                      horizontal
                      label="i5 Tag 2 Group:"
                      label-for="tag2_group_selection">
          <b-form-select id="tag2_group_selection"
                        :options="tag2GroupOptions"
                        v-model="tag2GroupId"
                        :disabled="tagGroupsDisabled"
                        @input="tagGroupInput"
                        @change="tagGroupChanged">
          </b-form-select>
        </b-form-group>
      </b-col>
    </b-row>
    <b-row class="form-group form-row">
      <b-col>
        <!-- by pool/plate seq/plate fixed select dropdown -->
        <b-form-group id="by_pool_plate_options_group"
                      label="By Pool/Plate Option:"
                      label-for="by_pool_plate_options">
          <b-form-select id="by_pool_plate_options"
                        :options="walkingByOptions"
                        v-model="walkingBy"
                        @input="updateTagParams">
          </b-form-select>
        </b-form-group>
      </b-col>
      <b-col>
        <!-- in rows/columns select dropdown -->
        <b-form-group id="by_rows_columns_group"
                      label="By Rows/Columns:"
                      label-for="by_rows_columns">
          <b-form-select id="by_rows_columns"
                        :options="directionOptions"
                        v-model="direction"
                        @input="updateTagParams">
          </b-form-select>
        </b-form-group>
      </b-col>
    </b-row>
    <b-row class="form-group form-row">
      <b-col>
        <!-- start at tag select dropdown -->
        <b-form-group id="offset_tags_by_group"
                      label="Start at tag number (offset):"
                      label-for="offset_tags_by_options">
          <b-form-select id="offset_tags_by_options"
                        :options="offsetTagsByOptions"
                        v-model="offsetTagsByOption"
                        :disabled="offsetDisabled"
                        @input="updateTagParams">
          </b-form-select>
        </b-form-group>
      </b-col>
      <b-col>
        <!-- tags per well select dropdown -->
        <b-form-group id="tags_per_well_group"
                      label="Tags per well:"
                      label-for="tags_per_well">
          <b-form-select id="tags_per_well"
                        :options="tagsPerWellOptions"
                        v-model="tagsPerWellOption"
                        @input="updateTagParams">
          </b-form-select>
        </b-form-group>
      </b-col>
    </b-row>

    <!-- TODO tag replacement pallette -->

  </b-container>
</template>

<script>
  import PlateScan from 'shared/components/PlateScan'

  export default {
    name: 'CustomTaggedPlateManipulations',
    data () {
      return {
        tagPlate: null,
        tagPlateWasScanned: false,
        tagPlateScanDisabled: false,
        tag1GroupId: null,
        tag2GroupId: null,
        walkingBy: 'by_plate_seq',
        direction: 'by_rows',
        tagsPerWellOption: null,
        startAtTagMin: 1,
        startAtTagStep: 1,
        startAtTagNumber: null
      }
    },
    props: {
      api: { required: false },
      tag1GroupOptions: { type: Array },
      tag2GroupOptions: { type: Array },
      // TODO change values to match sequencescape
      walkingByOptions: { type: Array, default: () =>{ return [
          { value: null, text: 'Please select a by Pool/Plate Option...' },
          { value: 'by_pool', text: 'By Pool' },
          { value: 'by_plate_seq', text: 'By Plate (Sequential)' },
          { value: 'by_plate_fixed', text: 'By Plate (Fixed)' }
        ]}
      },
      // TODO change values to match sequencescape
      directionOptions: { type: Array, default: () =>{ return [
          { value: null, text: 'Select a by Row/Column Option...' },
          { value: 'by_rows', text: 'By Rows' },
          { value: 'by_columns', text: 'By Columns' }
        ]}
      },
      numberOfTags: { type: Number, default: 0 },
      numberOfTargetWells: { type: Number, default: 0 },
      // TODO Tags per well should be fixed absed on plate purpose (mostly 1, chromium 4)
      tagsPerWellOptions: { type: Array, default: () =>{ return [
          { value: null, text: 'Select how many tags per well...' },
          { value: 1, text: '1' },
          { value: 4, text: '4' }
        ]}
      },
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
        if(data.state=== 'valid' && data.plate) {
          this.validTagPlateScanned(data)
        }
        if(data.state=== 'empty' && !data.plate) {
          this.emptyTagPlate()
        }
      },
      validTagPlateScanned(data) {
        this.tagPlate = { ...data.plate }
        this.tagPlateWasScanned = true

        if(data.plate.lot.tag_layout_template.tag_group.id) {
          this.tag1GroupId = data.plate.lot.tag_layout_template.tag_group.id
        } else {
          this.tag1GroupId = null
        }

        if(data.plate.lot.tag_layout_template.tag2_group.id) {
          this.tag2GroupId = data.plate.lot.tag_layout_template.tag2_group.id
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
      },
      updateTagParams(_value) {
        const updatedData = {
          tag1GroupId: this.tag1GroupId,
          tag2GroupId: this.tag2GroupId,
          walkingBy: this.walkingBy,
          direction: this.direction,
          startAtTagNumber: this.startAtTagNumber
        }
        this.$emit('tagparamsupdated', updatedData)
      }
    },
    computed: {
      tagGroupsDisabled: function () {
        return (typeof this.tagPlate != "undefined" && this.tagPlate !== null)
      },
      startAtTagMax: function () {
        const numTags = this.numberOfTags
        const numTargets = this.numberOfTargetWells

        if(numTags === 0 || numTargets === 0) {
          return 0
        }
        return numTags - numTargets + 1
      },
      startAtTagDisabled: function () {
        return (!this.startAtTagMax || this.startAtTagMax <= 1)
      },
      startAtTagPlaceholder: function () {
        let phTxt
        const tagMax = this.startAtTagMax

        if(tagMax <= 0) {
          if(this.numberOfTargetWells === 0) {
            phTxt = 'No target wells found..'
          } else if(this.numberOfTags === 0) {
            phTxt = 'Select tags first..'
          } else {
            phTxt = 'Not enough tags..'
          }
        } else if(tagMax === 1) {
          phTxt = 'No spare tags..'
        } else {
          phTxt = 'Enter an offset value..'
        }

        return phTxt
      },
    },
    components: {
      'lb-plate-scan': PlateScan
    }
  }

</script>
