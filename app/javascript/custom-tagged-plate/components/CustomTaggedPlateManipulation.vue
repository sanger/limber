<template>
  <b-container fluid>
    <b-row class="form-group form-row">
      <!-- TODO requires v-if on state, if tag groups have been selected disable this scan box -->
      <!-- tag plate scan -->
      <b-col>
          <b-form-group label="Scan in the tag plate you wish to use">
            <b-form-input v-model="form.tagPlateBarcode"
                          type="text"
                          placeholder="Scan the tag plate here...">
            </b-form-input>
            <!-- <lb-plate-scan v-for="i in sourcePlateNumber"
                           :api="devourApi"
                           :label="'Plate ' + i"
                           :key="i"
                           :includes="{wells: {'requests_as_source': 'primer_panel', aliquots: {'request': 'primer_panel'}}}"
                           :selects="{ plates: [ 'labware_barcode', 'wells', 'uuid', 'number_of_rows', 'number_of_columns' ],
                                       requests: [ 'primer_panel', 'uuid'],
                                       wells: ['position', 'requests_as_source', 'aliquots', 'uuid'],
                                       aliquots: ['request'] }"
                           v-on:change="updatePlate(i, $event)"></lb-plate-scan> -->
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
                        v-model="form.tag1Group">
          </b-form-select>
          <!-- alternate Tag group 1 label -->
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
                        v-model="form.tag2Group">
          </b-form-select>
          <!-- alternate Tag group 2 label -->
          <!-- TODO v-else on state -->
        </b-form-group>
      </b-col>
    </b-row>
    <b-row class="form-group form-row">
      <b-col>
        <!-- by pool/plate seq/plate fixed select dropdown -->
        <b-form-group id="by_options_group"
                      label="By Pool/Plate Option:"
                      label-for="by_options">
          <b-form-select id="by_options"
                        :options="byPoolPlateOptions"
                        v-model="form.byPoolPlateOption">
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
                        v-model="form.byRowColOption">
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
                        v-model="form.startAtTagOption">
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
                        v-model="form.tagsPerWellOption">
          </b-form-select>
        </b-form-group>
      </b-col>
    </b-row>

    <!-- tag replacement pallette -->
    <!-- TODO -->

  </b-container>
</template>

<script>
  // import PlateScan from 'shared/components/PlateScan'

  export default {
    name: 'CustomTaggedPlateManipulations',
    data () {
      return {
        form: {
          tagPlateBarcode: null,
          tag1Group: null,
          tag2Group: null,
          byPoolPlateOption: 'by_pool',
          byRowColOption: 'by_rows',
          startAtTagOption: 1,
          tagsPerWellOption: 1
        },
        // TODO fetch these from database, values are the group ids? or the full oligo lists?
        tag1GroupOptions: [
          { value: null, text: 'Please select an i7 Tag 1 group...' },
          { value: 1, text: 'i7 From DB num 1' },
          { value: 2, text: 'i7 From DB num 2' },
          { value: 3, text: 'i7 From DB num 3' }
        ],
        // TODO fetch these from database
        tag2GroupOptions: [
          { value: null, text: 'Please select an i5 Tag 2 group...' },
          { value: 1, text: 'i5 From DB num 1' },
          { value: 2, text: 'i5 From DB num 2' },
          { value: 3, text: 'i5 From DB num 3' }
        ],
        // TODO check what values should be and what transform they do (see generic lims)
        byPoolPlateOptions: [
          { value: null, text: 'Please select a by Pool/Plate Option...' },
          { value: 'by_pool', text: 'By Pool' },
          { value: 'by_plate_seq', text: 'By Plate (Sequential)' },
          { value: 'by_plate_fixed', text: 'By Plate (Fixed)' }
        ],
        // TODO check what values should be and what transform they do (see generic lims)
        byRowColOptions: [
          { value: null, text: 'Select a by Row/Column Option...' },
          { value: 'by_rows', text: 'By Rows' },
          { value: 'by_columns', text: 'By Columns' }
        ],
        // TODO this one needs to be dynamic based on calculations (see generic lims)
        // TODO change to number field with max, min and step parameters
        startAtTagOptions: [
          { value: null, text: 'Select which tag index to start at...' },
          { value: 1, text: '1' },
          { value: 2, text: '2' },
          { value: 3, text: '3' },
          { value: 4, text: '4' },
          { value: 5, text: '5' },
          { value: 6, text: '6' }
        ],
        // TODO Tags per well should be fixed absed on plate purpose (mostly 1, chromium 4)
        tagsPerWellOptions: [
          { value: null, text: 'Select how many tags per well...' },
          { value: 1, text: '1' },
          { value: 4, text: '4' }
        ]
      }
    },
    props: {
      // DO NOT MUTATE THESE IN THIS COMPONENT!
    },
    created: function () {
    },
    computed: {
    },
    methods: {
     //  watch: { 'thing': function() { //put your addThing code here, as you now have the thing variable set. } },
     //  // TODO on changing anything in this form we want to trigger an update of the child plate wells
     //  // NB we do not want to mutate any props in this component.
     //  // TODO v-on:change appears to happen BEFORE the value is updated
     //  changePlateOptions: function() {
     //    console.log('in manipulation changeChildPlateWells, form values = ')
     //    console.log('tagPlateBarcode = ' + this.form.tagPlateBarcode)
     //    console.log('tag1Group = ' + this.form.tag1Group)
     //    console.log('tag2Group = ' + this.form.tag2Group)
     //    console.log('byPoolPlateOption = ' + this.form.byPoolPlateOption)
     //    console.log('byRowColOption = ' + this.form.byRowColOption)
     //    console.log('startAtTagOption = ' + this.form.startAtTagOption)
     //    console.log('tagsPerWellOption = ' + this.form.tagsPerWellOption)
     //    this.$emit('updateChildWells', this.form);
     // }
    },
    components: {
      // 'lb-plate-scan': PlateScan
    },
    watch: {
     'form.byPoolPlateOption': function (newVal, oldVal) {
        console.log('watched by pool newVal = ' + newVal)
        console.log('watched by pool newVal = ' + oldVal)
        this.$emit('updateChildWells', this.form)
      }
      // TODO add all other form fields?
    }
    // ,
    // watch: {
    //   form: {
    //     byPoolPlateOption: function(value) {
    //       console.log('watched by pool value = ' + value)
    //       console.log('tagPlateBarcode = ' + this.form.tagPlateBarcode)
    //       console.log('tag1Group = ' + this.form.tag1Group)
    //       console.log('tag2Group = ' + this.form.tag2Group)
    //       console.log('byPoolPlateOption = ' + this.form.byPoolPlateOption)
    //       console.log('byRowColOption = ' + this.form.byRowColOption)
    //       console.log('startAtTagOption = ' + this.form.startAtTagOption)
    //       console.log('tagsPerWellOption = ' + this.form.tagsPerWellOption)
    //     }
    //   }
    // }
  }

</script>
