<template>
  <b-container fluid>
    <b-row class="form-group form-row">
      <b-col>
          <b-form-group id="tag_plate_scan_group"
                        label="Scan in the tag plate you wish to use here...">
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
        <b-form-group id="walking_by_options_group"
                      label="Walking By Options:"
                      label-for="walking_by_options">
          <b-form-select id="walking_by_options"
                        :options="walkingByOptions"
                        v-model="walkingBy"
                        @input="updateTagParams">
          </b-form-select>
        </b-form-group>
      </b-col>
      <b-col>
        <b-form-group id="direction_options_group"
                      label="Directions Options:"
                      label-for="direction_options">
          <b-form-select id="direction_options"
                        :options="directionOptions"
                        v-model="direction"
                        @input="updateTagParams">
          </b-form-select>
        </b-form-group>
      </b-col>
    </b-row>
    <b-row class="form-group form-row">
      <b-col>
        <b-form-group id="offset_tags_by_group"
                      label="Offset tags by:"
                      label-for="offset_tags_by_input"
                      :invalid-feedback="offsetTagsByInvalidFeedback"
                      :valid-feedback="offsetTagsByValidFeedback"
                      :state="offsetTagsByState">
          <b-form-input id="offset_tags_by_input"
                        type="number"
                        :min="offsetTagsByMin"
                        :max="offsetTagsByMax"
                        step="1"
                        :placeholder="offsetTagsByPlaceholder"
                        :state="offsetTagsByState"
                        v-model="offsetTagsBy"
                        :disabled="offsetTagsByDisabled"
                        @input="updateTagParams">
          </b-form-input>
        </b-form-group>
      </b-col>
      <b-col>
        <b-form-group id="tags_per_well_group"
                      label="Tags per well:"
                      label-for="tags_per_well">
          <b-form-input id="tags_per_well"
                        type="number"
                        v-bind:value="tagsPerWell"
                        :disabled="true">
          </b-form-input>
        </b-form-group>
      </b-col>
    </b-row>
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
        walkingBy: 'manual by plate',
        direction: 'row',
        offsetTagsByMin: 0,
        offsetTagsBy: 0
      }
    },
    props: {
      api: { required: false },
      tag1GroupOptions: { type: Array },
      tag2GroupOptions: { type: Array },
      numberOfTags: { type: Number, default: 0 },
      numberOfTargetWells: { type: Number, default: 0 },
      tagsPerWell: { type: Number, default: 1 }
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
        if(data.state === 'valid' && data.plate) {
          this.validTagPlateScanned(data)
        } else if(data.state === 'empty' && !data.plate) {
          this.emptyTagPlate()
        }
      },
      validTagPlateScanned(data) {
        this.tagPlate = { ...data.plate }
        this.tagPlateWasScanned = true
        this.offsetTagsBy = 0

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
        this.offsetTagsBy = 0
      },
      tagGroupInput() {
        this.updateTagPlateScanDisabled()
      },
      updateTagParams(_value) {
        const updatedData = {
          tagPlate: this.tagPlate,
          tag1GroupId: this.tag1GroupId,
          tag2GroupId: this.tag2GroupId,
          walkingBy: this.walkingBy,
          direction: this.direction,
          offsetTagsBy: Number.parseInt(this.offsetTagsBy)
        }

        this.$emit('tagparamsupdated', updatedData)
      }
    },
    computed: {
      walkingByOptions() {
        if(this.tagsPerWell > 1) {
          this.walkingBy = 'as group by plate'
          return [{ value: 'as group by plate', text: 'As Group By Plate' }]
        } else {
          this.walkingBy = 'manual by plate'
          return [
            { value: null, text: 'Please select a by Walking By Option...' },
            { value: 'manual by pool', text: 'By Pool' },
            { value: 'manual by plate', text: 'By Plate (Sequential)' },
            { value: 'wells of plate', text: 'By Plate (Fixed)' }
          ]
        }
      },
      directionOptions() {
        this.direction = 'row'
        return [
          { value: null, text: 'Please select a Direction Option...' },
          { value: 'row', text: 'By Rows' },
          { value: 'column', text: 'By Columns' },
          { value: 'inverse row', text: 'By Inverse Rows' },
          { value: 'inverse column', text: 'By Inverse Columns' }
        ]
      },
      tagGroupsDisabled() {
        return (typeof this.tagPlate != "undefined" && this.tagPlate !== null)
      },
      offsetTagsByMax() {
        if(this.numberOfTags === 0 || this.numberOfTargetWells === 0) {
          return null
        }
        return this.numberOfTags - this.numberOfTargetWells
      },
      offsetTagsByDisabled() {
        return (!this.offsetTagsByMax || this.offsetTagsByMax <= 0)
      },
      offsetTagsByPlaceholder() {
        if(this.numberOfTags === 0) { return 'Select tags first...' }

        if(this.numberOfTargetWells === 0) { return 'No target wells...' }

        if(this.offsetTagsByMax < 0) { return 'Not enough tags...' }

        if(this.offsetTagsByMax === 0) { return 'No spare tags...' }

        return 'Enter offset number...'
      },
      offsetTagsByState() {
        return (!this.offsetTagsByMax || this.offsetTagsByMax <= 0) ? null : this.offsetTagsByWithinLimits
      },
      offsetTagsByWithinLimits() {
        return ((this.offsetTagsBy >= this.offsetTagsByMin) &&
                (this.offsetTagsBy <= this.offsetTagsByMax)) ? true : false
      },
      offsetTagsByInvalidFeedback() {
        if(!this.offsetTagsByMax || this.offsetTagsByMax <= 0) { return '' }

        let chk
        chk = this.offsetTagsByCheckTooLow
        if(!chk.valid) { return chk.message }

        chk = this.offsetTagsByCheckTooHigh
        if(!chk.valid) { return chk.message }

        return ''
      },
      offsetTagsByCheckTooLow() {
        let ret = { valid: true, message: '' }

        if(this.offsetTagsBy < this.offsetTagsByMin) {
          ret.valid = false
          ret.message = 'Offset must be greater than or equal to ' + this.offsetTagsByMin
        }

        return ret
      },
      offsetTagsByCheckTooHigh() {
        let ret = { valid: true, message: '' }

        if(this.offsetTagsBy > this.offsetTagsByMax) {
          ret.valid = false
          ret.message = 'Offset must be less than or equal to ' + this.offsetTagsByMax
        }

        return ret
      },
      offsetTagsByValidFeedback() {
        return (this.offsetTagsByState ? 'Valid' : '')
      }
    },
    components: {
      'lb-plate-scan': PlateScan
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
