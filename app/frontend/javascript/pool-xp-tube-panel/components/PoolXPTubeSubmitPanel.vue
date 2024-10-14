<template>
  <div :class="{ 'bordered-badge p-1': displayStatus }">
    <b-button
      id="pool_xp_tube_submit_button"
      name="pool_xp_tube_submit_button"
      :disabled="isButtonDisabled"
      :variant="buttonStyle"
      :class="{ 'btn-gray': isButtonDisabled }"
      size="lg"
      block
      @click="handleSubmit"
    >
      {{ buttonText }}
    </b-button>
    <b-badge
      v-if="displayStatus"
      size="lg"
      :class="['p-2', 'mt-2', 'd-block', 'badge-light', 'text-info']"
      :style="{ fontSize: '1.25 rem' }"
    >
      <b-spinner v-show="displaySpinner" small type="border" class="mr-2" />
      Status: {{ statusText }}
    </b-badge>
  </div>
</template>

<script>
/**
 * Enum for the possible states of the component
 */
const StateEnum = {
  INITIAL: 'initial', // The default state or the initial state when component is first loaded
  FETCHING_TUBE: 'fetching', // The state when the component is checking if the tube exists in Traction
  REFETCHING_TUBE: 'refetching', // The state when the component is rechecking if the tube exists in Traction
  TUBE_NOT_FOUND: 'tube_not_found', // The state when the tube is not found in Traction
  TUBE_FOUND: 'tube_found', // The state when the tube is found in Traction
  SUBMITTING: 'submitting', // The state when the component is submitting the tube to Traction
  WAITING: 'waiting', // The state when the component is waiting for Traction to process the tube
  SUCCESS: 'success', // The state when the tube is successfully added to Traction
  FAILURE_FETCH_TUBE: 'failure_fetch_tube', // The state when the component fails to fetch the tube from Traction
  FAILURE_ADD_TUBE: 'failure_add_tube', // The state when the component fails to add the tube to Traction
  INVALID_TRACTION_URL: 'invalid_traction_url', // The state when the Traction URL is invalid
  INVALID_SEQUENCESCAPE_URL: 'invalid_sequencescape_url', // The state when the Sequencescape URL is invalid
  INVALID_BARCODE: 'invalid_barcode', //  The state when the barcode is invalid
  INVALID_USER_ID: 'invalid_user_id', //  The state when the user ID is invalid
}

const StatusTexts = {
  [StateEnum.INITIAL]: '',
  [StateEnum.FETCHING_TUBE]: 'Retrieving tube information from Traction...',
  [StateEnum.REFETCHING_TUBE]: 'Retrieving tube information from Traction...',
  [StateEnum.TUBE_FOUND]: 'Tube found in Traction',
  [StateEnum.SUBMITTING]: 'Submitting tube to Traction...',
  [StateEnum.SUCCESS]: 'Tube successfully added',
  [StateEnum.FAILURE_FETCH_TUBE]: 'Unable to retrieve tube from Traction. Please try again',
  [StateEnum.FAILURE_ADD_TUBE]: 'Unable to add tube. Please try submitting again.',
  [StateEnum.INVALID_TRACTION_URL]: 'Invalid Traction URL',
  [StateEnum.INVALID_SEQUENCESCAPE_URL]: 'Invalid Sequencescape URL',
  [StateEnum.INVALID_BARCODE]: 'Invalid barcode',
  [StateEnum.INVALID_USER_ID]: 'Invalid user ID',
}
export default {
  name: 'PoolXPTubeSubmitPanel',
  props: {
    barcode: {
      type: String,
      required: true,
    },
    userId: {
      type: String,
      required: true,
    },
    sequencescapeApiUrl: {
      type: String,
      required: true,
    },
    sequencescapeUrl: {
      type: String,
      required: true,
    },
    tractionUrl: {
      type: String,
      required: true,
    },
  },
  data: function () {
    return {
      state: StateEnum.INITIAL,
      isSubmitted: false,
      testBarcode: this.barcode,
    }
  },
  computed: {
    statusText() {
      return StatusTexts[this.state]
    },
    buttonStyle() {
      return (
        {
          [StateEnum.INITIAL]: 'primary text-green',
          [StateEnum.FETCHING_TUBE]: 'outline-primary',
          [StateEnum.TUBE_FOUND]: 'success',
          [StateEnum.SUBMITTING]: 'outline-primary',
          [StateEnum.SUCCESS]: 'success text-green',
          [StateEnum.FAILURE_FETCH_TUBE]: 'warning',
          [StateEnum.REFETCHING_TUBE]: 'warning',
          [StateEnum.FAILURE_ADD_TUBE]: 'warning',
        }[this.state] || 'danger'
      )
    },
    buttonText() {
      return (
        {
          [StateEnum.FAILURE_FETCH_TUBE]: 'Retrieve tube from Traction',
          [StateEnum.REFETCHING_TUBE]: 'Retrieve tube from Traction',
        }[this.state] || 'Submit Tube to Traction'
      )
    },
    displayStatus() {
      return this.state !== StateEnum.INITIAL
    },
    isButtonDisabled() {
      return !(
        this.state === StateEnum.INITIAL ||
        this.state === StateEnum.FAILURE_ADD_TUBE ||
        this.state === StateEnum.FAILURE_FETCH_TUBE
      )
    },
    displaySpinner() {
      return (
        this.state === StateEnum.FETCHING_TUBE ||
        this.state === StateEnum.SUBMITTING ||
        this.state === StateEnum.REFETCHING_TUBE
      )
    },
    sequencescapeApiExportUrl() {
      return `${this.sequencescapeApiUrl}/bioscan/export_pool_xp_to_traction`
    },
    tractionCheckTubeUrl() {
      if (!this.barcode || !this.tractionUrl) return ''
      return `${this.tractionUrl}/pacbio/tubes?filter[barcode]=${this.testBarcode}`
    },
    submitPayload() {
      return {
        data: {
          attributes: {
            barcode: this.barcode,
          },
        },
      }
    },
  },

  async mounted() {
    this.validateProps()
    if (this.state !== StateEnum.INITIAL) return
    const isTubeFound = await this.checkTubeInTraction()
    if (isTubeFound) {
      this.state = StateEnum.TUBE_FOUND
    }
  },
  methods: {
    validateProps() {
      if (!this.barcode) {
        this.state = StateEnum.INVALID_BARCODE
        return
      }
      if (!this.userId) {
        this.state = StateEnum.INVALID_USER_ID
        return
      }
      if (!this.sequencescapeApiUrl) {
        this.state = StateEnum.INVALID_SEQUENCESCAPE_URL
        return
      }
      if (!this.sequencescapeUrl) {
        this.state = StateEnum.INVALID_SEQUENCESCAPE_URL
        return
      }
      if (!this.tractionUrl) {
        this.state = StateEnum.INVALID_TRACTION_URL
        return
      }
    },
    async checkTubeInTraction() {
      try {
        const response = await fetch(this.tractionCheckTubeUrl)
        let isTubeFound = false
        if (response.ok) {
          const data = await response.json()
          if (data.data && data.data.length > 0) {
            isTubeFound = true
          }
        }
        return isTubeFound
      } catch (error) {
        return false
      }
    },

    handleSubmit() {
      if (this.state === StateEnum.FAILURE_FETCH_TUBE) {
        this.state = StateEnum.REFETCHING_TUBE
        this.testBarcode = 'TRAC-2-50'
        this.pollTractionForTube()
      } else {
        this.submitTube()
      }
    },
    async submitTube() {
      this.state = StateEnum.SUBMITTING
      try {
        const response = await fetch(this.sequencescapeApiExportUrl, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(this.submitPayload),
        })
        if (response.ok) {
          this.isSubmitted = true
          this.state = StateEnum.FETCHING_TUBE
          this.pollTractionForTube()
        } else {
          this.state = StateEnum.FAILURE_ADD_TUBE
        }
      } catch (error) {
        console.error('Error submitting tube to Traction:', error)
        this.state = StateEnum.FAILURE_ADD_TUBE
      }
    },

    async pollTractionForTube() {
      const maxAttempts = 5
      let attempts = 0
      const interval = 2000 // 2 seconds
      const poll = async () => {
        if (attempts > maxAttempts) {
          this.state = StateEnum.FAILURE_FETCH_TUBE
          return
        }
        // if(attempts ==3) {
        //   this.testBarcode = 'TRAC-2-50';
        // }
        const isTubeFound = await this.checkTubeInTraction()
        if (isTubeFound) {
          this.state = StateEnum.TUBE_FOUND
        } else {
          attempts++
          setTimeout(poll, interval)
        }
      }
      poll()
    },
  },
}
</script>

<style scoped>
.tooltip {
  font-size: 1rem;
}
.bordered-badge {
  background-color: #f8f9fa; /* Light background color */
  color: #343a40; /* Dark text color */
  border: 2px solid #d3d3d3; /* Light gray border color */
  border-radius: 0.25rem; /* Rounded corners */
}
.btn-gray {
  background-color: white !important; /* Light gray background color */
  border-color: #d3d3d3 !important; /* Light gray border color */
  color: #6c757d !important; /* Dark gray text color */
}
</style>
