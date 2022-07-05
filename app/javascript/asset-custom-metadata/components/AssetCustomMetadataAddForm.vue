<template>
  <div>
    <b-form @submit="submit">
      <b-form-group
        v-for="(obj, name, index) in normalizedCustomMetadataFields"
        id="custom-metadata-input-form"
        :key="index"
        label-cols="2"
        :label="name"
        :label-for="name"
      >
        <b-form-input :id="obj['key']" v-model="form[obj['key']]"></b-form-input>
      </b-form-group>

      <b-button
        id="asset_custom_metadata_submit_button"
        :disabled="disabled"
        type="submit"
        :variant="buttonStyle"
        size="lg"
        block
        >{{ buttonText }}</b-button
      >
    </b-form>
  </div>
</template>

<script>
// show every field from config
// store custom_metadatum_collections id, if it exists
// populate config with fields from DB
// onSubmit remove any fields that have no data
// send a patch or post request, depending whether metadata already exists (id)
// all metadata should be overritten
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
      previous_success: null,
      form: {},
    }
  },
  computed: {
    inProgress() {
      return !this.customMetadata()
    },
    customMetadatumCollectionsId() {
      return this.$root.$data.customMetadatumCollectionsId
    },
    normalizedCustomMetadataFields() {
      return JSON.parse(this.customMetadataFields)
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
    disabled() {
      return {
        pending: this.isCustomMetadataInvalid(),
        busy: true,
        success: true,
        failure: false,
      }[this.state]
    },
  },
  mounted() {
    this.setupForm()
    this.fetchCustomMetadata()
  },
  methods: {
    setupForm() {
      let initialForm = {}

      Object.values(this.normalizedCustomMetadataFields).map((obj) => {
        initialForm[obj['key']] = ''
      })

      this.form = initialForm
    },
    async fetchCustomMetadata() {
      await this.$root.$data.refreshCustomMetadata()

      if (this.$root.$data.customMetadata != undefined) {
        Object.keys(this.$root.$data.customMetadata).map((key) => {
          this.form[key] = this.$root.$data.customMetadata[key]
        })
      }
    },
    async submit() {
      let payload = this.form
      Object.keys(payload).forEach((key) => {
        if (payload[key] === '') {
          delete payload[key]
        }
      })

      this.state = 'busy'

      const successful = await this.$root.$data.addCustomMetadata(this.customMetadatumCollectionsId, payload)
      if (successful) {
        this.state = 'success'
        this.previous_success = true
      } else {
        this.state = 'failure'
        this.previous_success = false
      }
    },
    isCustomMetadataInvalid() {
      if (this.previous_success != null && this.previous_success) {
        this.state = 'pending'
      }
      return false
    },
  },
}
</script>
