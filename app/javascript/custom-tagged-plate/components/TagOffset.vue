<template>
  <b-form-group
    id="offset_tags_by_group"
    label="Offset tags by:"
    label-for="offset_tags_by_input"
    :invalid-feedback="offsetTagsByInvalidFeedback"
    :valid-feedback="offsetTagsByValidFeedback"
    :state="offsetTagsByState"
  >
    <b-form-input
      id="offset_tags_by_input"
      v-model="offsetTagsBy"
      type="number"
      :min="offsetTagsByMin"
      :max="offsetTagsByMax"
      step="1"
      :placeholder="offsetTagsByPlaceholder"
      :state="offsetTagsByState"
      @input="offsetTagChanged"
    />
  </b-form-group>
</template>

<script>

export default {
  name: 'TagOffset',
  props: {
    // The current number of useable tags, calculated by the parent component
    // and used to determine tag offset limits.
    numberOfTags: {
      type: Number,
      default: 0
    },
    // The number of target wells, calculated by the parent component and
    // used to determine the tag offset limits.
    numberOfTargetWells: {
      type: Number,
      default: 0
    },
    // The initial value of offset
    initialOffsetTagsBy: {
      type: Number,
      default: 0
    }
  },
  data () {
    return {
      offsetTagsByMin: 0, // holds the tag offset minimum value
      offsetTagsBy: this.initialOffsetTagsBy, // holds the entered tag offset number
    }
  },
  computed: {
    offsetTagsByMax() {
      if(this.numberOfTags === 0 || this.numberOfTargetWells === 0) {
        return null
      }
      return this.numberOfTags - this.numberOfTargetWells
    },
    isOffsetTagsByMaxValid() {
      return (this.offsetTagsByMax && this.offsetTagsByMax > 0)
    },
    isOffsetTagsByWithinLimits() {
      return ((this.offsetTagsBy >= this.offsetTagsByMin) &&
              (this.offsetTagsBy <= this.offsetTagsByMax)) ? true : false
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
    offsetTagsByPlaceholder() {
      let placeholder = 'Enter offset number...'

      if(this.numberOfTags === 0) {
        placeholder = 'Select tags first...'
      } else if(this.numberOfTargetWells === 0) {
        placeholder = 'No target wells...'
      } else if(this.offsetTagsByMax < 0) {
        placeholder = 'Not enough tags...'
      } else if(this.offsetTagsByMax === 0) {
        placeholder = 'No spare tags...'
      }

      return placeholder
    },
    offsetTagsByState() {
      return (this.isOffsetTagsByMaxValid) ? this.isOffsetTagsByWithinLimits : null
    },
    offsetTagsByValidFeedback() {
      return this.offsetTagsByState ? 'Valid' : ''
    },
    offsetTagsByInvalidFeedback() {
      if(this.isOffsetTagsByMaxValid) {
        let isChkLow = this.offsetTagsByCheckTooLow
        if(!isChkLow.valid) {
          return isChkLow.message
        }

        let isChkHigh = this.offsetTagsByCheckTooHigh
        if(!isChkHigh.valid) {
          return isChkHigh.message
        }
      }

      return ''
    }
  },
  methods: {
    offsetTagChanged() {
      this.$emit('tagoffsetchanged', this.offsetTagsBy)
    }
  }
}

</script>
