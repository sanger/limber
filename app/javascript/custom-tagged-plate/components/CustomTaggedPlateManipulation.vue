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
                        v-model="form.tag1GroupId"
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
                        v-model="form.tag2GroupId"
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
                        :options="byPoolPlateOptions"
                        v-model="form.byPoolPlateOption"
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
                        :options="byRowColOptions"
                        v-model="form.byRowColOption"
                        @input="updateTagParams">
          </b-form-select>
        </b-form-group>
      </b-col>
    </b-row>
    <b-row class="form-group form-row">
      <b-col>
        <!-- start at tag select dropdown -->
        <b-form-group id="start_at_tag_group"
                      label="Start at Tag number:"
                      label-for="start_at_tag_options">
          <b-form-select id="start_at_tag_options"
                        :options="startAtTagOptions"
                        v-model="form.startAtTagOption"
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
                        v-model="form.tagsPerWellOption"
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
        form: {
          tagPlateBarcode: null,
          tag1GroupId: null,
          tag2GroupId: null,
          byPoolPlateOption: 'by_plate_seq',
          byRowColOption: 'by_rows',
          startAtTagOption: null,
          tagsPerWellOption: null
        }
      }
    },
    props: {
      api: { required: false },
      tag1GroupOptions: { type: Array, required: true },
      tag2GroupOptions: { type: Array, required: true },
      // TODO check what values should be and what transform they do (see generic lims)
      byPoolPlateOptions: { type: Array, default: () =>{ return [
          { value: null, text: 'Please select a by Pool/Plate Option...' },
          { value: 'by_pool', text: 'By Pool' },
          { value: 'by_plate_seq', text: 'By Plate (Sequential)' },
          { value: 'by_plate_fixed', text: 'By Plate (Fixed)' }
        ]}
      },
      // TODO check what values should be and what transform they do (see generic lims)
      byRowColOptions: { type: Array, default: () =>{ return [
          { value: null, text: 'Select a by Row/Column Option...' },
          { value: 'by_rows', text: 'By Rows' },
          { value: 'by_columns', text: 'By Columns' }
        ]}
      },
      // TODO this one needs to be dynamic based on calculations (see generic lims)
      // TODO change to number field with max, min and step parameters
      startAtTagOptions: { type: Array, default: () =>{ return [
          { value: null, text: 'Select which tag index to start at...' },
          { value: 1, text: '1' },
          { value: 2, text: '2' },
          { value: 3, text: '3' },
          { value: 4, text: '4' },
          { value: 5, text: '5' },
          { value: 6, text: '6' }
        ]}
      },
      // TODO Tags per well should be fixed absed on plate purpose (mostly 1, chromium 4)
      tagsPerWellOptions: { type: Array, default: () =>{ return [
          { value: null, text: 'Select how many tags per well...' },
          { value: 1, text: '1' },
          { value: 4, text: '4' }
        ]}
      },
    },
    created: function () {
    },
    computed: {
      tagGroupsDisabled: function () {
        if (typeof this.tagPlate != "undefined" && this.tagPlate !== null) {
          return true
        }
        return false
      }
    },
    // NB. event handlers must be in the methods section
    methods: {
      updateTagPlateScanDisabled() {
        if(this.tagPlateWasScanned) {
          this.tagPlateScanDisabled = false
        } else {
          if(this.form.tag1GroupId || this.form.tag2GroupId) {
            this.tagPlateScanDisabled = true
          } else {
            this.tagPlateScanDisabled = false
          }
        }
        this.$emit('tagparamsupdated', this.form)
      },
      tagPlateScanned(data) {
        // data.plate.lot.tag_layout_template.id
        // this.tagLayoutWalkingAlgorithm = data.plate.lot.tag_layout_template.walking_by // e.g.
        // WALKING_ALGORITHMS = 'wells in pools', 'wells of plate', 'manual by pool', 'as group by plate', 'manual by plate', 'quadrants'

        // this.tagLayoutDirectionAlgorithm = data.plate.lot.tag_layout_template.direction // e.g.
        // DIRECTIONS = 'column','row','inverse column','inverse row,'column then row'

        // this.form.tag1GroupFromScan = data.plate.lot.tag_layout_template.tag_group.name
        // this.form.tag2GroupFromScan = data.plate.lot.tag_layout_template.tag2_group.name

        // this.tagGroupTagsFromScan = data.plate.lot.tag_layout_template.tag_group.tags
        // this.form.tag2GroupTagsFromScan = data.plate.lot.tag_layout_template.tag2_group.tags

        // data.plate.lot.tag_layout_template.tag_group.tags.length
        // data.plate.lot.tag_layout_template.tag_group.tags[0].index
        // data.plate.lot.tag_layout_template.tag_group.tags[0].oligo

        // N.B. There is an initial trigger to here happens when user clicks on the scan field (state 'searching', plate null).
        // The PlateScan component displays the error messages for us
        console.log('tagPlateScanned: returned data = ', JSON.stringify(data))

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
          this.form.tag1GroupId = data.plate.lot.tag_layout_template.tag_group.id
        } else {
          this.form.tag1GroupId = null
        }

        if(data.plate.lot.tag_layout_template.tag2_group.id) {
          this.form.tag2GroupId = data.plate.lot.tag_layout_template.tag2_group.id
        } else {
          this.form.tag2GroupId = null
        }

        this.updateTagPlateScanDisabled()
      },
      emptyTagPlate() {
        this.tagPlate = null
        this.form.tag1GroupId = null
        this.form.tag2GroupId = null
        this.updateTagPlateScanDisabled()
      },
      tagGroupChanged() {
        this.tagPlateWasScanned = false
      },
      tagGroupInput() {
        this.updateTagPlateScanDisabled()
      },
      updateTagParams(_value) {
        this.$emit('tagparamsupdated', this.form)
      }
    },
    components: {
      'lb-plate-scan': PlateScan
    }
  }

</script>
