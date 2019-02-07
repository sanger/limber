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
            <!-- NB. includes and fields lists must not contain spaces -->
            <lb-plate-scan id="tag_plate_scan"
                           :api="api"
                           :label="'Tag Plate'"
                           :plateType="'qcable'"
                           includes="lot,lot.tag_layout_template,lot.tag_layout_template.tag_group,lot.tag_layout_template.tag2_group"
                           :fields="{ lots: 'uuid,tag_layout_template',
                                      tag_layout_templates: 'uuid,tag_group,tag2_group,direction,walking_by',
                                      tag_groups: 'uuid,name,tags' }"
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
        tagPlate: {},
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
      api: { required: false },
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
        // TODO split this data out to extract the tag plate info, the lot, the tag groups and set
        // them to trigger the display of the tag group names in the GUI, and store the tags (indexes and oligos).
        // should trigger the emit to update tag params and redraw of the main screen.

        // data.plate.lot.tag_layout_template.id
        // this.tagLayoutWalkingAlgorithm = data.plate.lot.tag_layout_template.walking_by // e.g.
        // WALKING_ALGORITHMS = 'wells in pools', 'wells of plate', 'manual by pool', 'as group by plate', 'manual by plate', 'quadrants'

        // this.tagLayoutDirectionAlgorithm = data.plate.lot.tag_layout_template.direction // e.g.
        // DIRECTIONS = 'column','row','inverse column','inverse row,'column then row'

        // this.tagGroupFromScan = data.plate.lot.tag_layout_template.tag_group.name
        // this.tag2GroupFromScan = data.plate.lot.tag_layout_template.tag2_group.name

        // this.tagGroupTagsFromScan = data.plate.lot.tag_layout_template.tag_group.tags
        // this.tag2GroupTagsFromScan = data.plate.lot.tag_layout_template.tag2_group.tags

        // data.plate.lot.tag_layout_template.tag_group.tags.length
        // data.plate.lot.tag_layout_template.tag_group.tags[0].index
        // data.plate.lot.tag_layout_template.tag_group.tags[0].oligo


        // TODO what if any of these are null?

        // data looks like:
        // {"id":"16157","type":"qcables","uuid":"15947e78-14dd-11e9-aac5-68b599768938","state":"available","lot":{"id":"167","type":"lots","uuid":"08f846b8-d2e8-11e8-b689-68b59976a384","tag_layout_template":{"id":"71","type":"tag_layout_templates","uuid":"41e210fa-70a8-11e8-a0f1-68b599768938","direction":"column","walking_by":"wells of plate","tag_group":{"id":"206","type":"tag_groups","uuid":"56362416-7093-11e8-8815-68b599768938","name":"IDT for Illumina i7 UDI v1","tags":[{"index":1,"oligo":"CCGCGGTT"},{"index":2,"oligo":"TTATAACC"},{"index":3,"oligo":"GGACTTGG"},{"index":4,"oligo":"AAGTCCAA"},{"index":5,"oligo":"ATCCACTG"},{"index":6,"oligo":"GCTTGTCA"},{"index":7,"oligo":"CAAGCTAG"},{"index":8,"oligo":"TGGATCGA"},{"index":9,"oligo":"AGTTCAGG"},{"index":10,"oligo":"GACCTGAA"},{"index":11,"oligo":"TCTCTACT"},{"index":12,"oligo":"CTCTCGTC"},{"index":13,"oligo":"CCAAGTCT"},{"index":14,"oligo":"TTGGACTC"},{"index":15,"oligo":"GGCTTAAG"},{"index":16,"oligo":"AATCCGGA"},{"index":17,"oligo":"TAATACAG"},{"index":18,"oligo":"CGGCGTGA"},{"index":19,"oligo":"ATGTAAGT"},{"index":20,"oligo":"GCACGGAC"},{"index":21,"oligo":"GGTACCTT"},{"index":22,"oligo":"AACGTTCC"},{"index":23,"oligo":"GCAGAATT"},{"index":24,"oligo":"ATGAGGCC"},{"index":25,"oligo":"ACTAAGAT"},{"index":26,"oligo":"GTCGGAGC"},{"index":27,"oligo":"CTTGGTAT"},{"index":28,"oligo":"TCCAACGC"},{"index":29,"oligo":"CCGTGAAG"},{"index":30,"oligo":"TTACAGGA"},{"index":31,"oligo":"GGCATTCT"},{"index":32,"oligo":"AATGCCTC"},{"index":33,"oligo":"TACCGAGG"},{"index":34,"oligo":"CGTTAGAA"},{"index":35,"oligo":"AGCCTCAT"},{"index":36,"oligo":"GATTCTGC"},{"index":37,"oligo":"TCGTAGTG"},{"index":38,"oligo":"CTACGACA"},{"index":39,"oligo":"TAAGTGGT"},{"index":40,"oligo":"CGGACAAC"},{"index":41,"oligo":"ATATGGAT"},{"index":42,"oligo":"GCGCAAGC"},{"index":43,"oligo":"AAGATACT"},{"index":44,"oligo":"GGAGCGTC"},{"index":45,"oligo":"ATGGCATG"},{"index":46,"oligo":"GCAATGCA"},{"index":47,"oligo":"GTTCCAAT"},{"index":48,"oligo":"ACCTTGGC"},{"index":49,"oligo":"ATATCTCG"},{"index":50,"oligo":"GCGCTCTA"},{"index":51,"oligo":"AACAGGTT"},{"index":52,"oligo":"GGTGAACC"},{"index":53,"oligo":"CAACAATG"},{"index":54,"oligo":"TGGTGGCA"},{"index":55,"oligo":"AGGCAGAG"},{"index":56,"oligo":"GAATGAGA"},{"index":57,"oligo":"TGCGGCGT"},{"index":58,"oligo":"CATAATAC"},{"index":59,"oligo":"GATCTATC"},{"index":60,"oligo":"AGCTCGCT"},{"index":61,"oligo":"CGGAACTG"},{"index":62,"oligo":"TAAGGTCA"},{"index":63,"oligo":"TTGCCTAG"},{"index":64,"oligo":"CCATTCGA"},{"index":65,"oligo":"ACACTAAG"},{"index":66,"oligo":"GTGTCGGA"},{"index":67,"oligo":"TTCCTGTT"},{"index":68,"oligo":"CCTTCACC"},{"index":69,"oligo":"GCCACAGG"},{"index":70,"oligo":"ATTGTGAA"},{"index":71,"oligo":"ACTCGTGT"},{"index":72,"oligo":"GTCTACAC"},{"index":73,"oligo":"CAATTAAC"},{"index":74,"oligo":"TGGCCGGT"},{"index":75,"oligo":"AGTACTCC"},{"index":76,"oligo":"GACGTCTT"},{"index":77,"oligo":"TGCGAGAC"},{"index":78,"oligo":"CATAGAGT"},{"index":79,"oligo":"ACAGGCGC"},{"index":80,"oligo":"GTGAATAT"},{"index":81,"oligo":"AACTGTAG"},{"index":82,"oligo":"GGTCACGA"},{"index":83,"oligo":"CTGCTTCC"},{"index":84,"oligo":"TCATCCTT"},{"index":85,"oligo":"AGGTTATA"},{"index":86,"oligo":"GAACCGCG"},{"index":87,"oligo":"CTCACCAA"},{"index":88,"oligo":"TCTGTTGG"},{"index":89,"oligo":"TATCGCAC"},{"index":90,"oligo":"CGCTATGT"},{"index":91,"oligo":"GTATGTTC"},{"index":92,"oligo":"ACGCACCT"},{"index":93,"oligo":"TACTCATA"},{"index":94,"oligo":"CGTCTGCG"},{"index":95,"oligo":"TCGATATC"},{"index":96,"oligo":"CTAGCGCT"}],"links":{"self":"http://localhost:3000/api/v2/tag_groups/206"}},"tag2_group":{"id":"207","type":"tag_groups","uuid":"b56d0b34-7093-11e8-a0e8-68b59976a384","name":"IDT for Illumina i5 UDI v1","tags":[{"index":1,"oligo":"AGCGCTAG"},{"index":2,"oligo":"GATATCGA"},{"index":3,"oligo":"CGCAGACG"},{"index":4,"oligo":"TATGAGTA"},{"index":5,"oligo":"AGGTGCGT"},{"index":6,"oligo":"GAACATAC"},{"index":7,"oligo":"ACATAGCG"},{"index":8,"oligo":"GTGCGATA"},{"index":9,"oligo":"CCAACAGA"},{"index":10,"oligo":"TTGGTGAG"},{"index":11,"oligo":"CGCGGTTC"},{"index":12,"oligo":"TATAACCT"},{"index":13,"oligo":"AAGGATGA"},{"index":14,"oligo":"GGAAGCAG"},{"index":15,"oligo":"TCGTGACC"},{"index":16,"oligo":"CTACAGTT"},{"index":17,"oligo":"ATATTCAC"},{"index":18,"oligo":"GCGCCTGT"},{"index":19,"oligo":"ACTCTATG"},{"index":20,"oligo":"GTCTCGCA"},{"index":21,"oligo":"AAGACGTC"},{"index":22,"oligo":"GGAGTACT"},{"index":23,"oligo":"ACCGGCCA"},{"index":24,"oligo":"GTTAATTG"},{"index":25,"oligo":"AACCGCGG"},{"index":26,"oligo":"GGTTATAA"},{"index":27,"oligo":"CCAAGTCC"},{"index":28,"oligo":"TTGGACTT"},{"index":29,"oligo":"CAGTGGAT"},{"index":30,"oligo":"TGACAAGC"},{"index":31,"oligo":"CTAGCTTG"},{"index":32,"oligo":"TCGATCCA"},{"index":33,"oligo":"CCTGAACT"},{"index":34,"oligo":"TTCAGGTC"},{"index":35,"oligo":"AGTAGAGA"},{"index":36,"oligo":"GACGAGAG"},{"index":37,"oligo":"AGACTTGG"},{"index":38,"oligo":"GAGTCCAA"},{"index":39,"oligo":"CTTAAGCC"},{"index":40,"oligo":"TCCGGATT"},{"index":41,"oligo":"CTGTATTA"},{"index":42,"oligo":"TCACGCCG"},{"index":43,"oligo":"ACTTACAT"},{"index":44,"oligo":"GTCCGTGC"},{"index":45,"oligo":"AAGGTACC"},{"index":46,"oligo":"GGAACGTT"},{"index":47,"oligo":"AATTCTGC"},{"index":48,"oligo":"GGCCTCAT"},{"index":49,"oligo":"ATCTTAGT"},{"index":50,"oligo":"GCTCCGAC"},{"index":51,"oligo":"ATACCAAG"},{"index":52,"oligo":"GCGTTGGA"},{"index":53,"oligo":"CTTCACGG"},{"index":54,"oligo":"TCCTGTAA"},{"index":55,"oligo":"AGAATGCC"},{"index":56,"oligo":"GAGGCATT"},{"index":57,"oligo":"CCTCGGTA"},{"index":58,"oligo":"TTCTAACG"},{"index":59,"oligo":"ATGAGGCT"},{"index":60,"oligo":"GCAGAATC"},{"index":61,"oligo":"CACTACGA"},{"index":62,"oligo":"TGTCGTAG"},{"index":63,"oligo":"ACCACTTA"},{"index":64,"oligo":"GTTGTCCG"},{"index":65,"oligo":"ATCCATAT"},{"index":66,"oligo":"GCTTGCGC"},{"index":67,"oligo":"AGTATCTT"},{"index":68,"oligo":"GACGCTCC"},{"index":69,"oligo":"CATGCCAT"},{"index":70,"oligo":"TGCATTGC"},{"index":71,"oligo":"ATTGGAAC"},{"index":72,"oligo":"GCCAAGGT"},{"index":73,"oligo":"CGAGATAT"},{"index":74,"oligo":"TAGAGCGC"},{"index":75,"oligo":"AACCTGTT"},{"index":76,"oligo":"GGTTCACC"},{"index":77,"oligo":"CATTGTTG"},{"index":78,"oligo":"TGCCACCA"},{"index":79,"oligo":"CTCTGCCT"},{"index":80,"oligo":"TCTCATTC"},{"index":81,"oligo":"ACGCCGCA"},{"index":82,"oligo":"GTATTATG"},{"index":83,"oligo":"GATAGATC"},{"index":84,"oligo":"AGCGAGCT"},{"index":85,"oligo":"CAGTTCCG"},{"index":86,"oligo":"TGACCTTA"},{"index":87,"oligo":"CTAGGCAA"},{"index":88,"oligo":"TCGAATGG"},{"index":89,"oligo":"CTTAGTGT"},{"index":90,"oligo":"TCCGACAC"},{"index":91,"oligo":"AACAGGAA"},{"index":92,"oligo":"GGTGAAGG"},{"index":93,"oligo":"CCTGTGGC"},{"index":94,"oligo":"TTCACAAT"},{"index":95,"oligo":"ACACGAGT"},{"index":96,"oligo":"GTGTAGAC"}],"links":{"self":"http://localhost:3000/api/v2/tag_groups/207"}},"links":{"self":"http://localhost:3000/api/v2/tag_layout_templates/71"}},"links":{"self":"http://localhost:3000/api/v2/lots/167"}},"asset":null,"links":{"self":"http://localhost:3000/api/v2/qcables/16157"}}
        if(data['plate'] !== null) {
          // this.$set(this.tagPlate, data)
          // this.tagPlate = { ...data }
          //Cannot set reactive property on undefined, null, or primitive value: null
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
