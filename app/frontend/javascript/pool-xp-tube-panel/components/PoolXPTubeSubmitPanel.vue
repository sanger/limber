<template>
  <div class="d-flex justify-content-between align-items-center">
    <label
      id="pool_xp_tube_submit_status"
      :class="['p-2', 'mt-2', stateStyles.text]"
      :style="{ fontSize: '1.0rem', display: 'flex', alignItems: 'center' }"
    >
      <b-spinner v-if="displaySpinner" id="progress_spinner" small type="border" class="mr-2" />
      <component :is="statusIcon" v-else class="mr-2" :color="stateStyles.icon" />
      {{ statusText }}
    </label>

    <b-button
      id="pool_xp_tube_submit_button"
      name="pool_xp_tube_submit_button"
      :disabled="isButtonDisabled"
      :variant="stateStyles.button"
      :class="['w-50']"
      @click="handleSubmit"
    >
      {{ buttonText }}
    </b-button>
  </div>
</template>

<script>
import ReadyIcon from '../../icons/ReadyIcon.vue'
import SuccessIcon from '../../icons/SuccessIcon.vue'
import ErrorIcon from '../../icons/ErrorIcon.vue'
import TubeSearchIcon from '../../icons/TubeSearchIcon.vue'
const maxPollttempts = 10
const pollInterval = 1000

/**
 * Enum for the possible states of the component
 */
const StateEnum = {
  INITIAL: 'initial', // The default state or the initial state when component is first loaded
  CHECKING_TUBE_EXISTS: 'fetching', // The state when the component is checking if the tube exists in Traction
  TUBE_ALREADY_EXPORTED: 'tube_exists', // The state when the component is rechecking if the tube exists in Traction
  POLLING_TUBE: 'polling', // The state when the component is polling Traction to check if the tube is exported
  TUBE_EXPORT_SUCESS: 'tube_exported', // The state when the tube is successfully exported to Traction
  FAILURE_POLL_TUBE: 'failure_poll_tube', // The state when the component fails to poll Traction for the tube
  FAILURE_EXPORT_TUBE: 'failure_export_tube', // The state when the component fails to export the tube to Traction
  FAILURE_ADD_TUBE: 'failure_add_tube', // The state when the component fails to add the tube to Traction
  FAILURE_EXPORT_TUBE_AFTER_RECHECK: 'failure_export_tube_after_recheck', // The state when the component fails to export the tube to Traction after rechecking
  INVALID_PROPS: 'invalid_props', // The state when the component receives invalid props
}

const StateData = {
  [StateEnum.INITIAL]: {
    statusText: 'Ready to export.',
    buttonText: 'Export',
    styles: { button: 'success', text: 'text-success', icon: 'green' },
    icon: ReadyIcon,
  },
  [StateEnum.CHECKING_TUBE_EXISTS]: {
    statusText: 'Checking tube is in Traction...',
    buttonText: 'Please wait',
    styles: { button: 'success', text: 'text-black', icon: 'black' },
    icon: TubeSearchIcon,
  },
  [StateEnum.TUBE_ALREADY_EXPORTED]: {
    statusText: 'Tube already exported to Traction.',
    buttonText: 'Open Traction.',
    styles: { button: 'success', text: 'text-success', icon: 'green' },
    icon: SuccessIcon,
  },
  [StateEnum.POLLING_TUBE]: {
    statusText: 'Tube is being exported',
    buttonText: 'Please wait',
    styles: { button: 'success', text: 'text-black', icon: 'green' },
    icon: null,
  },
  [StateEnum.TUBE_EXPORT_SUCESS]: {
    statusText: 'Tube has been exported to Traction.',
    buttonText: 'Open Traction.',
    styles: { button: 'success', text: 'text-success', icon: 'green' },
    icon: SuccessIcon,
  },
  [StateEnum.FAILURE_POLL_TUBE]: {
    statusText: 'Unable to check whether tube is in Traction. Try again?',
    buttonText: 'Refresh',
    styles: { button: 'warning', text: 'text-warning', icon: 'orange' },
    icon: ErrorIcon,
  },
  [StateEnum.FAILURE_EXPORT_TUBE]: {
    statusText: 'Unable to send tube to Traction. Try again?',
    buttonText: 'Retry',
    styles: { button: 'warning', text: 'text-warning', icon: 'warning' },
    icon: ErrorIcon,
  },
  [StateEnum.FAILURE_EXPORT_TUBE_AFTER_RECHECK]: {
    statusText: 'Unable to send tube to Traction',
    buttonText: 'Export',
    styles: { button: 'primary', text: 'text-danger', icon: 'red' },
    icon: ErrorIcon,
  },
  [StateEnum.INVALID_PROPS]: {
    statusText: 'Invalid Traction URL',
    buttonText: 'Invalid Traction URL',
    styles: { button: 'danger', text: 'text-danger', icon: 'red' },
    icon: ErrorIcon,
  },
  
}

export default {
  name: 'PoolXPTubeSubmitPanel',
  components: {
    ReadyIcon,
  },
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
    tractionServiceUrl: {
      type: String,
      required: true,
    },
    tractionUIUrl: {
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
      return StateData[this.state].statusText
    },
    buttonText() {
      return StateData[this.state].buttonText
    },
    stateStyles() {
      return StateData[this.state].styles || { button: 'danger', text: 'text-danger' }
    },
    statusIcon() {
      return StateData[this.state].icon
    },
   
    isButtonDisabled() {
      return (
        this.state === StateEnum.CHECKING_TUBE_EXISTS ||
        this.state === StateEnum.POLLING_TUBE ||
        this.state === StateEnum.INVALID_PROPS 
      )
    },
    displaySpinner() {
      return this.state === StateEnum.POLLING_TUBE
    },
    sequencescapeApiExportUrl() {
      return `${this.sequencescapeApiUrl}/bioscan/export_pool_xp_to_traction`
    },
    tractionCheckTubeUrl() {
      if (!this.barcode || !this.tractionServiceUrl) return ''
      return `${this.tractionServiceUrl}/pacbio/tubes?filter[barcode]=${this.testBarcode}`
    },
    tractionOpenTubeUrl() {
      if (!this.barcode || !this.tractionUIUrl) return ''
      return `${this.tractionUIUrl}/pacbio/libraries?filter_value=barcode&filter_input=${this.testBarcode}`
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
    if(this.state === StateEnum.INVALID_PROPS) return
    this.state = StateEnum.CHECKING_TUBE_EXISTS
    const isTubeFound = await this.checkTubeInTraction()
    this.state = isTubeFound ? StateEnum.TUBE_ALREADY_EXPORTED : StateEnum.INITIAL
  },
  methods: {
    validateProps() {
      if (!this.barcode || !this.userId || !this.sequencescapeApiUrl || !this.sequencescapeUrl || !this.tractionServiceUrl) {
        this.state = StateEnum.INVALID_PROPS
        return
      }
     
    },
    async checkTubeInTraction() {
      let isTubeFound = false
      try {
        const response = await fetch(this.tractionCheckTubeUrl)
        
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

    async handleSubmit() {
      switch (this.state) {
        case StateEnum.FAILURE_POLL_TUBE: {
          this.state = StateEnum.CHECKING_TUBE_EXISTS
          const isFound = await this.checkTubeInTraction()
          this.state = isFound ? StateEnum.TUBE_EXPORT_SUCESS : StateEnum.FAILURE_EXPORT_TUBE_AFTER_RECHECK
          break
        }
        case StateEnum.TUBE_EXPORT_SUCESS:
        case StateEnum.TUBE_ALREADY_EXPORTED: {
          // Open Traction in a new tab
          window.open(this.tractionOpenTubeUrl, '_blank')
          break
        }
        default:{
          await this.submitTube()
          break
        }
      }
    },
    async submitTube() {
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
          this.state = StateEnum.POLLING_TUBE
          this.pollTractionForTube()
        } else {
          this.state = StateEnum.FAILURE_EXPORT_TUBE
        }
      } catch (error) {
        console.error('Error submitting tube to Traction:', error)
        this.state = StateEnum.FAILURE_EXPORT_TUBE
      }
    },

    async pollTractionForTube() {
      let attempts = 0
      
      const poll = async () => {
        if (attempts > maxPollttempts) {
          this.state = StateEnum.FAILURE_POLL_TUBE
          return
        }
        // if(attempts ==3) {
        //   this.testBarcode = 'TRAC-2-50';
        // }
        const isTubeFound = await this.checkTubeInTraction()
        if (isTubeFound) {
          this.state = StateEnum.TUBE_EXPORT_SUCESS
          return
        } else {
          attempts++
          setTimeout(poll, pollInterval)
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
