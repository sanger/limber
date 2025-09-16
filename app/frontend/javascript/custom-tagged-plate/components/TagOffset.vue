<template>
  <b-form-group
    id="offset_tags_by_group"
    label="Offset tags by:"
    label-for="offset_tags_by_input"
    :invalid-feedback="offsetTagsByInvalidFeedback"
    valid-feedback="Great!"
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
      @update:model-value="offsetTagChanged"
    />
    <b-form-text>
      <strong> Tags will start from {{ offsetTagsByAsNumber + 1 }} </strong>
    </b-form-text>
  </b-form-group>
</template>

<script>
/**
 * Displays a tag offset input field.
 * The user can enter a value which is validated and emitted to the parent.
 * Validation is for guidance only and does not prevent emission.
 * It provides:
 * - A number input field with validation.
 */
export default {
  name: 'TagOffset',
  props: {
    // The current number of useable tags, calculated by the parent component
    // and used to determine tag offset limits.
    numberOfTags: {
      type: Number,
      default: 0,
    },
    // The number of target wells, calculated by the parent component and
    // used to determine the tag offset limits.
    numberOfTargetWells: {
      type: Number,
      default: 0,
    },
    // The tags per well number, determined by the plate purpose and used here
    // to compute the offset maximum.
    tagsPerWell: {
      type: Number,
      default: 1,
    },
  },
  emits: ['tagoffsetchanged'],
  data() {
    return {
      offsetTagsByMin: 0, // holds the tag offset minimum value
      offsetTagsBy: '0', // holds the entered tag offset number (input so string)
    }
  },
  computed: {
    offsetTagsByAsNumber() {
      return Number.parseInt(this.offsetTagsBy)
    },
    offsetTagsByMax() {
      if (this.numberOfTags === 0 || this.numberOfTargetWells === 0 || this.tagsPerWell === 0) {
        return null
      }

      const numTagsNeeded = this.numberOfTargetWells * this.tagsPerWell
      return Math.floor((this.numberOfTags - numTagsNeeded) / this.tagsPerWell)
    },
    isOffsetTagsByMaxValid() {
      return this.offsetTagsByMax && this.offsetTagsByMax > 0
    },
    isOffsetTagsByWithinLimits() {
      return this.offsetTagsByAsNumber >= this.offsetTagsByMin && this.offsetTagsByAsNumber <= this.offsetTagsByMax
        ? true
        : false
    },
    isOffsetTagsByTooHigh() {
      return this.offsetTagsByAsNumber > this.offsetTagsByMax
    },
    offsetTagsByPlaceholder() {
      let placeholder = 'Enter offset number...'

      if (this.numberOfTags === 0) {
        placeholder = 'Select tags first...'
      } else if (this.numberOfTargetWells === 0) {
        placeholder = 'No target wells...'
      } else if (this.offsetTagsByMax < 0) {
        placeholder = 'Not enough tags...'
      } else if (this.offsetTagsByMax === 0) {
        placeholder = 'No spare tags...'
      }

      return placeholder
    },
    offsetTagsByState() {
      if (!this.isOffsetTagsByMaxValid) {
        return null
      }
      if (this.offsetTagsBy === '' || this.offsetTagsBy === '0') {
        return null
      }
      return this.isOffsetTagsByWithinLimits
    },
    offsetTagsByInvalidFeedback() {
      if (this.isOffsetTagsByMaxValid && this.isOffsetTagsByTooHigh) {
        return 'Offset must be less than or equal to ' + this.offsetTagsByMax
      } else {
        if (!this.isOffsetTagsByWithinLimits && this.offsetTagsByMax < 0) {
          return 'Not enough tags to fill wells with aliquots'
        }
      }

      return ''
    },
  },
  methods: {
    offsetTagChanged() {
      this.$emit('tagoffsetchanged', this.offsetTagsByAsNumber)
    },
  },
}
</script>
