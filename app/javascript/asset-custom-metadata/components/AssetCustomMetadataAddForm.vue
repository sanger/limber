<template>
  <div v-if="customMetadataFieldsExist">
    <b-form @submit.prevent="submit">
      <b-form-group
        v-for="(obj, name, index) in normalizedFields"
        id="custom-metadata-input-form"
        :key="index"
        label-cols="2"
        :label="name"
        :label-for="name"
      >
        <!-- only show input for fields which are defined in config -->
        <b-form-input :id="obj['key']" v-model="form[obj['key']]" @update="onUpdate"></b-form-input>
      </b-form-group>

      <b-button id="asset_custom_metadata_submit_button" type="submit" :variant="buttonStyle" size="lg" block>{{
        buttonText
      }}</b-button>
    </b-form>
  </div>
</template>

<script>
// Get Custom Metadata fields from config and populate form
// Fetch the assets existing Custom Metadata and update form
// Store custom_metadatum_collections id, if it exists
// Show form inputs only for form field which are present in config
// onSubmit remove any fields that have no data
// Send a patch or post request, depending whether metadata already exists
// All metadata should be either created or overwrited
export default {
  name: 'AssetCustomMetadataAddForm',
  props: {
    customMetadataFields: {
      type: String,
      required: true,
    },
    assetId: {
      type: String,
      required: true,
    },
  },
  data: function () {
    return {
      state: 'pending',
      form: {},
      normalizedFields: JSON.parse(this.customMetadataFields),
    }
  },
  computed: {
    customMetadataFieldsExist() {
      return Object.keys(this.normalizedFields).length != 0
    },
    buttonText() {
      return {
        pending: 'Add Custom Metadata to Sequencescape',
        busy: 'Sending...',
        success: 'Custom Metadata successfully added',
        failure: 'Failed to add custom metadata, retry?',
      }[this.state]
    },
    buttonStyle() {
      return {
        pending: 'primary',
        busy: 'outline-primary',
        success: 'success',
        failure: 'danger',
      }[this.state]
    },
  },
  mounted() {
    this.setupForm()
    this.fetchCustomMetadata()
  },
  methods: {
    onUpdate() {
      if (this.state != 'pending') {
        this.state = 'pending'
      }
    },
    setupForm() {
      // initially create the form with only fields
      // which are provided in the config
      let initialForm = {}
      Object.values(this.normalizedFields).map((obj) => {
        initialForm[obj['key']] = ''
      })

      this.form = initialForm
    },
    async fetchCustomMetadata() {
      await this.$root.$data.refreshCustomMetadata()

      // update the form with all fetched data
      // even if fields are not specified by config
      // as these get filtered out in a later step,
      // as we might want to support updating all metadata fields
      // (such as robot info)
      if (Object.keys(this.$root.$data.customMetadata).length != 0) {
        Object.keys(this.$root.$data.customMetadata).map((key) => {
          this.form[key] = this.$root.$data.customMetadata[key]
        })
      }
    },
    async submit() {
      let payload = this.form

      // remove any empty fields, as these will then be removed
      // from the metadata
      Object.keys(payload).forEach((key) => {
        if (payload[key] === '') {
          delete payload[key]
        }
      })

      this.state = 'busy'

      let customMetadatumCollectionsId = this.$root.$data.customMetadatumCollectionsId
      const successful = await this.$root.$data.addCustomMetadata(customMetadatumCollectionsId, payload)
      if (successful) {
        this.state = 'success'
      } else {
        this.state = 'failure'
      }
    },
  },
}
</script>
