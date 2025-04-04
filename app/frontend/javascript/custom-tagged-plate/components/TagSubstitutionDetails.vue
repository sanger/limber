<template>
  <div>
    <p><strong>Tag Substitutions</strong></p>
    <b-container v-if="hasTagSubstitutions" fluid>
      <b-row>
        <b-col class="first-col"> Original Tag Id </b-col>
        <b-col>Substituted Tag Id</b-col>
        <b-col>Remove this substitution</b-col>
      </b-row>
      <b-row v-for="(tagSubstitutionValue, tagSubstitutionKey) in tagSubstitutions" :key="tagSubstitutionKey">
        <b-col :id="'original_tag_id_' + tagSubstitutionKey">
          {{ tagSubstitutionKey }}
        </b-col>
        <b-col :id="'substituted_tag_id_' + tagSubstitutionKey">
          {{ tagSubstitutionValue }}
        </b-col>
        <b-col>
          <div class="form-group form-row d-grid">
            <b-button
              :id="'remove_tag_id_' + tagSubstitutionKey + '_submit_button'"
              :name="'remove_tag_id_' + tagSubstitutionKey + '_button'"
              class="pb-2"
              size="sm"
              @click="removeSubstitution(tagSubstitutionKey)"
            >
              Remove
            </b-button>
          </div>
        </b-col>
      </b-row>
    </b-container>
    <div v-if="tagSubstitutionsAllowed" id="tag_substitutions_allowed">
      <p>Click on tagged wells to enter substitutions...</p>
    </div>
    <div v-else id="tag_substitutions_disallowed">
      <p>No tag substitutions allowed for this plate type.</p>
    </div>
  </div>
</template>

<script>
/**
 * Displays a list of any tag substitutions the user has entered.
 * Each row contains a remove button which triggers an emit of the selected
 * tag substitution for the parent to act upon (delete from the list).
 * It provides:
 * - A row for each tag substitution in the supplied list showing:
 *   - original tag map id
 *   - substituted tag map id
 *   - a remove button to indicate the row should be deleted (emits to parent)
 */
export default {
  name: 'TagSubstitutionDetails',
  props: {
    // a flag to indicate whether tag substitutions are allowed for this plate
    tagSubstitutionsAllowed: {
      type: Boolean,
      default: true,
    },
    // an object containing the tag map id substitutions e.g. { 2: 5, 8: 12 }
    tagSubstitutions: {
      type: Object,
      default: () => {
        return {}
      },
    },
  },
  emits: ['removetagsubstitution'],
  data() {
    return {}
  },
  computed: {
    hasTagSubstitutions() {
      return Object.keys(this.tagSubstitutions).length > 0 ? true : false
    },
  },
  methods: {
    removeSubstitution(origTagId) {
      this.$emit('removetagsubstitution', origTagId)
    },
  },
}
</script>
