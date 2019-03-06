<template>
  <div>
    <p><strong>Tag Substitutions</strong></p>
    <b-container fluid v-if="hasTagSubstitutions">
      <b-row>
        <b-col class="first-col">Original Tag Id</b-col>
        <b-col>Substituted Tag Id</b-col>
        <b-col>Remove this substitution</b-col>
      </b-row>
      <b-row v-for="(tagSubstitutionValue, tagSubstitutionKey) in tagSubstitutions" :key="tagSubstitutionKey">
        <b-col :id="'original_tag_id_' + tagSubstitutionKey">{{ tagSubstitutionKey }}</b-col>
        <b-col :id="'substituted_tag_id_' + tagSubstitutionKey">{{ tagSubstitutionValue }}</b-col>
        <b-col>
          <div class="form-group form-row">
            <b-button :name="'remove_tag_id_' + tagSubstitutionKey + '_button'" :id="'remove_tag_id_' + tagSubstitutionKey + '_submit_button'" class="pb-2" size="sm" block @click="removeSubstitution(tagSubstitutionKey)">Remove</b-button>
          </div>
        </b-col>
      </b-row>
    </b-container>
    <b-container v-else>
      <p>Click on tagged wells to add substitutions...</p>
    </b-container>
  </div>
</template>

<script>
  export default {
    name: 'CustomTaggedPlateDetails',
    data () {
      return {
      }
    },
    props: {
      tagSubstitutions: { type: Object, default: {} },
    },
    methods: {
      removeSubstitution(origTagId) {
        this.$emit('removetagsubstitution', origTagId)
      }
    },
    computed: {
      hasTagSubstitutions() {
        return Object.keys(this.tagSubstitutions).length > 0 ? true : false
      }
    }
  }
</script>
