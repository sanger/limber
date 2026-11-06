<template>
  <div class="d-grid gap-3">
    <lb-qc-field
      v-for="qcField in qcFields"
      :key="qcField.name"
      v-bind="qcField"
      :asset-uuid="assetUuid"
      @change="updateResult(qcField.name, $event)"
    />
    <b-button :disabled="disabled" :variant="buttonStyle" size="lg" @click="submit">
      {{ buttonText }}
    </b-button>
  </div>
</template>

<script>
import QcField from './QcField.vue'
import axios from 'axios'

export default {
  name: 'QcInformation',
  components: {
    'lb-qc-field': QcField,
  },
  props: {
    qcFields: {
      default: () => {
        return [
          { name: 'volume', units: 'ul' },
          {
            name: 'molarity',
            units: 'nM',
            assayTypes: ['Estimated', 'qPCR', 'Agilent Bioanalyser'],
          },
        ]
      },
      type: Array,
    },
    assetUuid: { type: String, required: true },
    sequencescapeApi: { type: String, default: 'http://localhost:3000/api/v2' },
  },
  data() {
    return {
      qcResults: {},
      axiosInstance: axios.create({
        baseURL: this.sequencescapeApi,
        timeout: 10000,
        headers: {
          Accept: 'application/vnd.api+json',
          'Content-Type': 'application/vnd.api+json',
        },
      }),
      state: 'pending',
    }
  },
  computed: {
    filledQcResults() {
      return Object.entries(this.qcResults).reduce((results, result) => {
        if (result[1].value.trim() !== '') {
          results.push(result[1])
        }
        return results
      }, [])
    },
    payload() {
      return {
        data: {
          type: 'qc_assays',
          attributes: {
            qc_results: this.filledQcResults,
          },
        },
      }
    },
    buttonText() {
      return {
        pending: 'Send to Sequencescape',
        busy: 'Sending...',
        success: 'Success',
        failure: 'Failed to send, retry?',
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
      return this.state == 'busy'
    },
  },
  methods: {
    updateResult(property, result) {
      this.qcResults[property] = result
    },
    submit() {
      this.state = 'busy'
      this.axiosInstance({
        method: 'post',
        url: 'qc_assays',
        data: this.payload,
      }).then(
        () => {
          this.state = 'success'
        },
        () => {
          this.state = 'failure'
        },
      )
    },
  },
}
</script>
