<template>
  <b-modal
    id="well_modal"
    ref="wellModalRef"
    :title="wellModalTitle"
    :ok-disabled="!wellModalState"
    @ok="handleWellModalOk"
    @shown="handleWellModalShown"
  >
    <form @submit.stop.prevent="handleWellModalSubmit">
      <b-container fluid>
        <b-row v-if="wellModalDetails.originalTag" class="form-group form-row">
          <b-col>
            <b-form-group
              id="original_tag_number_group"
              label="Original tag:"
              label-for="original_tag_number_input"
              readonly="true"
            >
              <b-form-input
                id="original_tag_number_input"
                type="number"
                :model-value="wellModalDetails.originalTag"
                readonly
              />
            </b-form-group>
          </b-col>
        </b-row>
        <b-row v-if="wellModalDetails.tagMapIds.length > 0" class="form-group form-row">
          <b-col>
            <b-form-group
              id="substitute_tag_number_group"
              label="Substitute tag:"
              label-for="substitute_tag_number_input"
              :invalid-feedback="wellModalInvalidFeedback"
              valid-feedback="Great!"
              :state="wellModalState"
            >
              <b-form-input
                id="substitute_tag_number_input"
                ref="focusThis"
                v-model="substituteTagId"
                type="number"
                placeholder="Enter a valid tag map id to substitute"
                :state="wellModalState"
              />
            </b-form-group>
          </b-col>
        </b-row>
        <b-row v-if="!wellModalDetails.validity.valid" class="form-group form-row">
          <b-col>
            <span id="well_error_message"
              ><strong>{{ wellModalDetails.validity.message }}</strong></span
            >
          </b-col>
        </b-row>
      </b-container>
    </form>
  </b-modal>
</template>

<script>
/**
 * Modal displayed to the user on clicking a tagged well on the plate, for them
 * to enter a tag map id to substitute the tag currently in the well.
 * It provides:
 * - The well position e.g. A1
 * - The original tag as determined by the tag layout and chosen layout
 * manipulation options.
 * - An input which shows the current substituted tag map id if one exists and
 * allows the user to pick a new tag map id
 * - An Ok button which triggers an emit of the substituted tag map id to the
 * parent.
 */
export default {
  name: 'WellModal',
  props: {
    // Holds all the details used by the well modal:
    // - position : the well position e.g. A1
    // - originalTag : the original tag map id as determined by the tag layout
    // - tagMapIds : the list of valid tag map ids as determined by the tag
    // groups chosen, used to validate the user entered substitute tag map id
    // - validity : the current validity of the well, with message displayed
    // if invalid e.g. 'tag clash with C8'
    // - existingSubstituteTagId : the current substitute tag id
    wellModalDetails: {
      type: Object,
      default: () => {
        return {
          position: '',
          originalTag: null,
          tagMapIds: [],
          validity: { valid: true, message: '' },
          existingSubstituteTagId: null,
        }
      },
    },
  },
  emits: ['wellmodalsubtituteselected'],
  data() {
    return {
      substituteTagId: null, // the input substitute tag map id (input so string)
    }
  },
  computed: {
    wellModalTitle() {
      return 'Well: ' + this.wellModalDetails.position + ' - Tag Substitution'
    },
    substituteTagIdAsNumber() {
      return this.substituteTagId ? Number.parseInt(this.substituteTagId) : null
    },
    wellModalState() {
      if (this.wellModalDetails.tagMapIds.length === 0) {
        return null
      }
      if (this.substituteTagId === null || this.substituteTagId === '') {
        return null
      }
      return this.wellModalDetails.tagMapIds.includes(this.substituteTagIdAsNumber)
    },
    wellModalInvalidFeedback() {
      if (this.substituteTagId === null) {
        return ''
      }
      return this.wellModalState ? '' : 'Number entered is not a valid tag map id'
    },
  },
  methods: {
    show() {
      this.$refs.wellModalRef.show()
    },
    hide() {
      this.$refs.wellModalRef.hide()
    },
    handleWellModalShown(_e) {
      if (this.wellModalDetails.existingSubstituteTagId) {
        this.substituteTagId = this.wellModalDetails.existingSubstituteTagId.toString()
      }
      if (this.wellModalDetails.tagMapIds.length > 0) {
        this.$refs.focusThis.focus()
      }
    },
    handleWellModalOk(_evt) {
      this.$emit('wellmodalsubtituteselected', this.substituteTagIdAsNumber)
      this.substituteTagId = null
    },
  },
}
</script>
