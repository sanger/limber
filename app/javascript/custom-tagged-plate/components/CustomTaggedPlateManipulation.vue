<template>
  <b-container fluid>
    <b-row class="form-group form-row">
      <!-- TODO requires v-if on state, if tag groups have been selected disable this scan box -->
      <!-- tag plate scan -->
      <b-col>
          <b-form-group id="tag_plate_scan_group"
                        label="Scan in the tag plate you wish to use here...">
            <!-- TODO scan plate, should in this case lookup a 'qcable' with barcode in a state of 'available' or 'exhausted' -->
            <!-- possible qcable states 'failed','passed','exhausted','destroyed','created','available','pending','qc_in_progress' -->
            <!-- qcable in ss has a with_barcode scope, qcable has a state and a lot, lot has a template (a tag_layout_template here),
            tag_layout_template should have a tag_group and tag2_group, plus walking_ and direction_algorithm, tag_groups have tags,
            tags have a tag_index (map_id) and aliquots, aliquots have a tag and tag2 -->

            <!-- TODO we also need to warn if the tag plate layout template is not 'by plate' -->
            <lb-plate-scan id="tag_plate_scan"
                           :api="devourApi"
                           :label="'Tag Plate'"
                           :plateType="'qcable'"
                           :includes="{ lots: { templates: ['tag_group','tag2_group'] }}"
                           :selects="{ qcables: [ 'state', 'lot' ],
                                       lot: [ 'template' ],
                                       tag_layout_template: [ 'tag_group', 'tag2_group', 'direction_algorithm', 'walking_algorithm' ],
                                       tag_group: [ 'name' ] }"
                           v-on:change="updatePlate($event)">
            </lb-plate-scan>
        </b-form-group>
      </b-col>
    </b-row>
    <b-row class="form-group form-row">
      <b-col>
         <!-- Tag group 1 select dropdown -->
         <!-- TODO required v-if state of tag 1 group selection -->
        <b-form-group id="tag1_group_selection_group"
                      horizontal
                      label="i7 Tag 1 Group:"
                      label-for="tag1_group_selection">
          <b-form-select id="tag1_group_selection"
                        :options="tag1GroupOptions"
                        v-model="form.tag1Group"
                        v-on:input="updateTagParams">
          </b-form-select>
          <!-- alternate Tag group 1 label -->
          <b-form-input id="tag1_group_from_tag_plate"
                        type="text"
                        :state="true"
                        :value="form.tag1GroupFromTagPlate"
                        :disabled="true">
          </b-form-input>
          <!-- TODO -->
        </b-form-group>
      </b-col>
    </b-row>
    <b-row class="form-group form-row">
      <b-col>
        <!-- Tag group 2 select dropdown -->
        <!-- TODO required v-if state of tag 2 group selection -->
        <b-form-group id="tag2_group_selection_group"
                      horizontal
                      label="i5 Tag 2 Group:"
                      label-for="tag2_group_selection">
          <b-form-select id="tag2_group_selection"
                        :options="tag2GroupOptions"
                        v-model="form.tag2Group"
                        v-on:input="updateTagParams">
          </b-form-select>
          <!-- alternate Tag group 2 label -->
          <b-form-input id="tag2_group_from_tag_plate"
                        type="text"
                        :state="true"
                        :value="form.tag2GroupFromTagPlate"
                        :disabled="true">
          </b-form-input>
          <!-- TODO v-else on state -->
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
                        v-on:input="updateTagParams">
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
                        v-on:input="updateTagParams">
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
                        v-on:input="updateTagParams">
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
                        v-on:input="updateTagParams">
          </b-form-select>
        </b-form-group>
      </b-col>
    </b-row>

    <!-- tag replacement pallette -->
    <!-- TODO -->

  </b-container>
</template>

<script>
  import PlateScan from 'shared/components/PlateScan'

  export default {
    name: 'CustomTaggedPlateManipulations',
    data () {
      return {
        tagPlate: null,
        form: {
          tagPlateBarcode: null,
          tag1Group: null,
          tag2Group: null,
          byPoolPlateOption: 'by_pool',
          byRowColOption: 'by_rows',
          startAtTagOption: null,
          tagsPerWellOption: null,
          tag1GroupFromTagPlate: 'filled when a valid tag plate is scanned',
          tag2GroupFromTagPlate: 'filled when a valid tag plate is scanned'
        }
      }
    },
    props: {
      devourApi: { type: Object, required: true },
      // TODO fetch these from database, values are the group ids? or the full oligo lists?
      // tag_group -> name, tags
      tag1GroupOptions: { type: Array, default: () =>{ return [
          { value: null, text: 'Please select an i7 Tag 1 group...' },
          { value: 1, text: 'i7 example tag group 1' },
          { value: 2, text: 'i7 example tag group 2' },
          { value: 3, text: 'i7 example tag group 3' }
        ]}
      },
      // TODO fetch these from database, same list as for tag_group (can pick two the same)
      tag2GroupOptions: { type: Array, default: () =>{ return [
          { value: null, text: 'Please select an i5 Tag 2 group...' },
          { value: 1, text: 'i5 example tag group 1' },
          { value: 2, text: 'i5 example tag group 2' },
          { value: 3, text: 'i5 example tag group 3' }
        ]}
      },
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
    },
    // NB. event handlers must be in the methods section
    methods: {
      updatePlate(data) {
        console.log('in update plate, data = ' + JSON.stringify(data))
        if(data['plate'] !== null) {
          this.$set(this.tagPlate, {...data })
          console.log('in update plate, this.tagPlate = ' + JSON.stringify(this.tagPlate))
        } else {
          // this.$set(this.tagPlate, null)
          console.log('in update plate, plate null')
        }
      },
      updateTagParams(value) {
        // TODO value is not used, is it needed?
        this.$emit('tagparamsupdated', this.form);
      }
    },
    components: {
      'lb-plate-scan': PlateScan
    }
  }

</script>
