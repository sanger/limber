<template>
  <b-modal
    id="well_modal"
    ref="wellModalRef"
    :title="wellModalTitle"
    :ok-disabled="!state"
    :ok-title="wellModalOkTitle"
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
              invalid-feedback="Number entered does not match a tag map id"
              valid-feedback="Great!"
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
    }
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
      return this.wellModalDetails.tagMapIds.includes(this.substituteTagIdAsNumber)
    },
    wellModalOkTitle() {
      return this.state ? 'Substitute Tag' : 'Enter a valid tag id...'
    }
  },
  methods: {
    show() {
      this.$refs.wellModalRef.show()
    },
    hide() {
      this.$refs.wellModalRef.hide()
    },
    handleWellModalShown(_e) {
      this.substituteTagId = this.wellModalDetails.existingSubstituteTagId
      this.$refs.focusThis.focus()
    },
    handleWellModalOk(_evt) {
      this.$emit('wellmodalsubtituteselected', this.substituteTagIdAsNumber )
      this.substituteTagId = null
    },
  }
}

</script>
