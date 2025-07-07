<template>
  <div v-if="customMetadataFieldsExist">
    <b-form @submit.prevent="submit">
      <b-form-group
        v-for="(item, index) in normalizedFields"
        id="custom-metadata-input-form"
        :key="index"
        label-cols="2"
        :label="item"
        :label-for="item"
      >
        <!-- only show input for fields which are defined in config -->
        <b-row>
          <b-col cols="10">
            <b-form-input :id="item" v-model="form[item]" @update:model-value="onUpdate"></b-form-input>
          </b-col>
          <b-col>
            <b-button
              v-b-tooltip.hover
              :href="url(item)"
              title="Find other labware with the same metadata in Sequencescape"
              variant="outline-primary"
            >
              <BoxArrowUpRight color="#007aff" />
            </b-button>
          </b-col>
        </b-row>
      </b-form-group>

      <div class="d-grid">
        <b-button id="labware_custom_metadata_submit_button" type="submit" :variant="buttonStyle" size="lg">
          {{ buttonText }}
        </b-button>
      </div>
    </b-form>
  </div>
</template>

<script>
// magnifiy glass
// on hover, say find other plates with this metadata
// with link to ss
// ss/advanced_search?metadata_key=field_name&metadata_value=test_value

// Get Custom Metadata fields from config and populate form
// Fetch the labwares existing Custom Metadata and update form
// Store custom_metadatum_collections id, if it exists
// Show form inputs only for form field which are present in config
// onSubmit remove any fields that have no data
// Send a patch or post request, depending whether metadata already exists
// All metadata should be either created or overwrited
import BoxArrowUpRight from '@/javascript/icons/BoxArrowUpRight.vue'
export default {
  name: 'LabwareCustomMetadataAddForm',
  components: {
    BoxArrowUpRight,
  },
  props: {
    labwareId: {
      type: String,
      required: true,
    },
    customMetadataFields: {
      type: String,
      required: true,
    },
    userId: {
      type: String,
      required: true,
    },
    sequencescapeApi: {
      type: String,
      required: true,
    },
    sequencescapeUrl: {
      type: String,
      required: true,
    },
  },
  data: function () {
    return {
      state: 'pending',
      form: {},
      normalizedFields: JSON.parse(this.customMetadataFields),
      customMetadatumCollectionsId: undefined,
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
    url(item) {
      return `${this.sequencescapeUrl}/advanced_search?metadata_key=${item}&metadata_value=${this.form[item]}`
    },
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
        initialForm[obj] = ''
      })
      this.form = initialForm
    },
    async fetchCustomMetadata() {
      let metadata = await this.refreshCustomMetadata()
      this.populateForm(metadata)
    },
    async refreshCustomMetadata() {
      let url = `${this.sequencescapeApi}/labware/${this.labwareId}?include=custom_metadatum_collection`
      let metadata = {}

      await fetch(url)
        .then((response) => {
          return response.json()
        })
        .then((data) => {
          if (data && data.included) {
            this.customMetadatumCollectionsId = data.included[0].id
            metadata = data.included[0].attributes.metadata
          }
        })
        .catch((error) => {
          console.error('Error:', error)
        })
      return metadata
    },
    populateForm(metadata) {
      // update the form with all fetched data
      // even if fields are not specified by config
      // as these get filtered out in a later step,
      // as we might want to support updating all metadata fields
      // (such as robot info)
      if (Object.keys(metadata).length != 0) {
        Object.keys(metadata).map((key) => {
          this.form[key] = metadata[key]
        })
      }
    },
    async submit() {
      this.state = 'busy'

      let metadata = this.form

      // remove any empty fields, as these will then be removed
      // from the metadata
      Object.keys(metadata).forEach((key) => {
        metadata[key] = metadata[key].trim()
        if (metadata[key] === '') {
          delete metadata[key]
        }
      })

      this.postData(metadata)
    },
    async postData(metadata = {}) {
      let url = this.buildUrl(this.customMetadatumCollectionsId)
      let method = this.customMetadatumCollectionsId ? 'PATCH' : 'POST'
      let body = this.buildPayload(method, this.customMetadatumCollectionsId, metadata)

      await fetch(url, {
        method,
        body: JSON.stringify(body),
        headers: { 'Content-Type': 'application/vnd.api+json' },
      })
        .then((response) => response.json())
        .then((data) => {
          if (data.errors) {
            throw data.errors
          }
          this.customMetadatumCollectionsId = data.data.id
          this.state = 'success'
        })
        .catch((error) => {
          console.error('Error:', error)
          this.state = 'failure'
        })
    },
    buildUrl(customMetadatumCollectionsId) {
      let path = customMetadatumCollectionsId
        ? `custom_metadatum_collections/${customMetadatumCollectionsId}`
        : 'custom_metadatum_collections'

      return `${this.sequencescapeApi}/${path}`
    },
    buildPayload(method, customMetadatumCollectionsId, metadata) {
      let patchPayload = {
        data: {
          id: customMetadatumCollectionsId,
          type: 'custom_metadatum_collections',
          attributes: {
            metadata: metadata,
          },
        },
      }

      let postPayload = {
        data: {
          type: 'custom_metadatum_collections',
          attributes: {
            user_id: this.userId,
            asset_id: this.labwareId,
            metadata: metadata,
          },
        },
      }
      return method == 'PATCH' ? patchPayload : postPayload
    },
  },
}
</script>

<style scoped>
.tooltip {
  font-size: 1rem;
}
</style>
