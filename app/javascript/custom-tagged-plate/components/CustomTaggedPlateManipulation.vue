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
        <b-form-group id="start_at_tag_group"
                      label="Start at tag number:"
                      label-for="start_at_tag_input"
                      :invalid-feedback="startAtTagInvalidFeedback"
                      :valid-feedback="startAtTagValidFeedback"
                      :state="startAtTagState">
          <b-form-input id="start_at_tag_input"
                        type="number"
                        :min="startAtTagMin"
                        :max="startAtTagMax"
                        :step="startAtTagStep"
                        :placeholder="startAtTagPlaceholder"
                        :state="startAtTagState"
                        v-model="startAtTagNumber"
                        :disabled="startAtTagDisabled"
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
        startAtTagMin: 1,
        startAtTagStep: 1,
        startAtTagNumber: null
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
        this.startAtTagNumber = null

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
        this.startAtTagNumber = null
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
          startAtTagNumber: this.startAtTagNumber
        }
        this.$emit('tagparamsupdated', updatedData)
      }
    },
    computed: {
      walkingByOptions: function () {
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
      directionOptions: function () {
        this.direction = 'row'
        return [
          { value: null, text: 'Please select a Direction Option...' },
          { value: 'row', text: 'By Rows' },
          { value: 'column', text: 'By Columns' },
          { value: 'inverse row', text: 'By Inverse Rows' },
          { value: 'inverse column', text: 'By Inverse Columns' }
        ]
      },
      tagGroupsDisabled: function () {
        return (typeof this.tagPlate != "undefined" && this.tagPlate !== null)
      },
      startAtTagMax: function () {
        const numTags = this.numberOfTags
        const numTargets = this.numberOfTargetWells

        if(numTags === 0 || numTargets === 0) {
          return null
        }
        return numTags - numTargets + 1
      },
      startAtTagDisabled: function () {
        return (!this.startAtTagMax || this.startAtTagMax <= 1)
      },
      startAtTagPlaceholder: function () {
        let phTxt
        const tagMax = this.startAtTagMax
        const numTags = this.numberOfTags
        const numTargets = this.numberOfTargetWells

        if(tagMax <= 0) {
          if(numTargets === 0) {
            phTxt = 'No target wells found..'
          } else if(numTags === 0) {
            phTxt = 'Select tags first..'
          } else {
            phTxt = 'Not enough tags..'
          }
        } else if(tagMax === 1) {
          phTxt = 'No spare tags..'
        } else {
          phTxt = 'Select starting tag..'
        }

        return phTxt
      },
      startAtTagState: function () {
        if(this.startAtTagNumber === null || this.startAtTagNumber === undefined || this.startAtTagNumber === '') { return null }
        if(!this.startAtTagMax || this.startAtTagMax <= 1) { return null }

        return this.startAtTagWithinLimits
      },
      startAtTagWithinLimits: function () {
        return ((this.startAtTagNumber >= this.startAtTagMin) &&
                (this.startAtTagNumber <= this.startAtTagMax) &&
                (this.startAtTagNumber % this.startAtTagStep === 0)) ? true : false
      },
      startAtTagInvalidFeedback: function () {
        if(!this.startAtTagMax || this.startAtTagMax <= 1) { return '' }
        if(this.startAtTagNumber === null || this.startAtTagNumber === undefined || this.startAtTagNumber === '') { return '' }

        let chk
        chk = this.startAtTagCheckTooLow
        if(!chk.valid) { return chk.message }

        chk = this.startAtTagCheckTooHigh
        if(!chk.valid) { return chk.message }

        chk = this.startAtTagCheckStep
        if(!chk.valid) { return chk.message }

        return ''
      },
      startAtTagCheckTooLow: function () {
        let ret = { valid: true, message: '' }

        if(this.startAtTagNumber < this.startAtTagMin) {
          ret.valid = false
          ret.message = 'Start must be greater than or equal to ' + this.startAtTagMin
        }

        return ret
      },
      startAtTagCheckTooHigh: function () {
        let ret = { valid: true, message: '' }

        if(this.startAtTagNumber > this.startAtTagMax) {
          ret.valid = false
          ret.message = 'Start must be less than or equal to ' + this.startAtTagMax
        }

        return ret
      },
      startAtTagCheckStep: function () {
        let ret = { valid: true, message: '' }

        if(this.startAtTagNumber >= this.startAtTagMin && this.startAtTagNumber <= this.startAtTagMax) {
          if(this.startAtTagNumber % this.startAtTagStep !== 0) {
            ret.valid = false
            ret.message = 'Start must be divisible by ' + this.startAtTagStep
          }
        }

        return ret
      },
      startAtTagValidFeedback: function () {
        return this.startAtTagState === true ? 'Valid' : ''
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
