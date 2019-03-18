<template>
  <b-modal
    id="well_modal"
    v-model="isWellModalVisible"
    :title="wellModalTitle"
    @ok="handleWellModalOk"
    @shown="handleWellModalShown"
  >
    <form @submit.stop.prevent="handleWellModalSubmit">
      <b-container fluid>
        <b-row class="form-group form-row">
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
                :value="wellModalDetails.originalTag"
                readonly
              />
            </b-form-group>
          </b-col>
        </b-row>
        <b-row class="form-group form-row">
          <b-col>
            <b-form-group
              id="substitute_tag_number_group"
              label="Substitute tag:"
              label-for="substitute_tag_number_input"
              :invalid-feedback="invalidFeedback"
              :valid-feedback="validFeedback"
              :state="state"
            >
              <b-form-input
                id="substitute_tag_number_input"
                ref="focusThis"
                v-model="substituteTagId"
                type="number"
                placeholder="Enter tag number to substitute"
                :state="state"
              />
            </b-form-group>
          </b-col>
        </b-row>
        <b-row
          v-if="!wellModalDetails.validity.valid"
          class="form-group form-row"
        >
          <b-col>
            <span id="well_error_message"><strong>{{ wellModalDetails.validity.message }}</strong></span>
          </b-col>
        </b-row>
      </b-container>
    </form>
  </b-modal>
</template>

<script>

export default {
  name: 'CustomTaggedPlateWellModal',
  props: {
    wellModalDetails: {
      type: Object, default: () => {
        return {
          position: '',
          originalTag: null,
          tagMapIds: [],
          validity: { valid: true, message: '' },
          existingSubstituteTagId: null
        }
      }
    },
    isWellModalVisible: { type: Boolean, default: false },
  },
  data () {
    return {
      substituteTagId: null
    }
  },
  computed: {
    wellModalTitle() {
      return ('Well: ' + this.wellModalDetails.position)
    },
    substituteTagIdAsNumber() {
      return (this.substituteTagId) ? Number.parseInt(this.substituteTagId) : null
    },
    state() {
      console.log('state, substituteTagIdAsNumber = ', this.substituteTagIdAsNumber)
      return this.wellModalDetails.tagMapIds.includes(this.substituteTagIdAsNumber)
    },
    validFeedback() {
      console.log('validFeedback, state = ', this.state)
      return this.state === true ? 'Valid' : ''
    },
    invalidFeedback() {
      console.log('invalidFeedback, state = ', this.state)
      return this.state === true ? '' : 'Number entered does not match a tag map id'
    },
  },
  methods: {
    handleWellModalShown(_e) {
      this.substituteTagId = this.wellModalDetails.existingSubstituteTagId
      this.$refs.focusThis.focus()
    },
    handleWellModalOk(evt) {
      // Prevent modal from closing unless conditions are met
      evt.preventDefault()
      // TODO this will not work for just messages e.g. empty well/no tags
      if (!this.substituteTagId) {
        alert('Please enter a tag to substitute then click Ok, or else cancel')
      } else {
        this.handleWellModalSubmit()
      }
    },
    handleWellModalSubmit() {
      this.$emit('wellmodalsubtituteselected', this.substituteTagId )
      this.substituteTagId = null
    },
  }
}

</script>
