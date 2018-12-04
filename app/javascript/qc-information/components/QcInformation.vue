<template>
<div>
  <lb-qc-field v-for="qcField in qcFields"
               v-bind="qcField"
               :assetUuid="assetUuid"
               :key="qcField.name"
               @change="updateResult(qcField.name, $event)">
  </lb-qc-field>
  <b-button :disabled="disabled" :variant="buttonStyle" size="lg" block @click="submit">{{ buttonText }}</b-button>
</div>
</template>

<script>

  import QcField from './QcField.vue'
  import ApiModule from 'shared/api'

  export default {
    name: 'QcInformation',
    data () {
      return {
        qcResults: {},
        Api: ApiModule({ baseUrl: this.sequencescapeApi }),
        state: 'pending'
      }
    },
    props: {
      qcFields: { default: () => {
        return [
          { name: 'volume', units: 'ul' },
          { name: 'molarity', units: 'nM', assayTypes: ['Estimated', 'qPCR', 'Agilent Bioanalyser'] }
        ] }
      },
      assetUuid: { default: String, required: true },
      sequencescapeApi: { type: String, default: 'http://localhost:3000/api/v2' }
    },
    computed: {
      filledQcResults() {
        return Object.entries(this.qcResults).reduce((results, result) => {
          if (result[1].value.trim() !== '') { results.push(result[1]) }
          return results
        }, [])
      },
      qcAssay() {
        return new this.Api.QcAssay({
          qcResults: this.filledQcResults
        })
      },
      buttonText() {
        return {
            'pending': 'Send to Sequencescape',
            'busy': 'Sending...',
            'success': 'Success',
            'failure': 'Failed to send, retry?'
        }[this.state]
      },
      buttonStyle() {
        return {
          'pending': 'primary',
          'busy': 'outline-primary',
          'success': 'success',
          'failure': 'danger'
        }[this.state]
      },
      disabled() {
        return this.state == 'busy'
      }
    },
    methods: {
      updateResult(property, result) {
        this.qcResults[property] = result
      },
      submit() {
        this.state = 'busy'
        this.qcAssay.save().then(
          () => { this.state = 'success' },
          () => { this.state = 'failure' }
        )
      }
    },
    components: {
        'lb-qc-field': QcField
      }
  }
</script>
