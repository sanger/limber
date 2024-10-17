<template>
  <div class="d-flex justify-content-between align-items-center">
    <label
      id="pool_xp_tube_export_status"
      :class="['p-2', 'mt-2', stateStyles.text]"
      :style="{ fontSize: '1.0rem', display: 'flex', alignItems: 'center' }"
    >
      <b-spinner v-show="displaySpinner" id="progress_spinner" small type="border" class="mr-2" />
      <component :is="statusIcon" id="status_icon" class="mr-1" :color="stateStyles.icon" />
      {{ statusText }}
    </label>

    <b-button
      id="pool_xp_tube_export_button"
      name="pool_xp_tube_export_button"
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
/**
 * Component to export a tube to Traction
 * @module components/PoolXPTubeSubmitPanel
 * @property {String} barcode - The barcode of the tube to be exported
 * @property {String} userId - The id of the user exporting the tube
 * @property {String} sequencescapeApiUrl - The URL of the Sequencescape API
 * @property {String} tractionServiceUrl - The URL of the Traction service
 * @property {String} tractionUIUrl - The URL of the Traction UI
 *
 * This component exports a tube to Traction and polls Traction to check if the tube is exported successfully.
 * It displays the status of the export and provides a button to export the tube.
 *
 * The component has the following states:
 *
 * 1. INITIAL
 *    - When the component is first loaded, it is in the INITIAL state.
 *    - On Mount, the component checks if the tube is already exported to Traction.
 *    - If the tube is found, the component transitions to the TUBE_ALREADY_EXPORTED state.
 *    - If the tube is not found, the component remains in the INITIAL state.
 *
 * 2. TUBE_ALREADY_EXPORTED
 *    - This state occurs if the tube is found in Traction during the initial check.
 *    - The component provides a button to open the tube in Traction.
 *
 * 3. FAILURE_EXPORT_TUBE
 *    - This state occurs if the request to export the tube to Traction fails.
 *    - The component provides a button to retry exporting the tube.
 *
 * 4. POLLING_TUBE
 *    - This state occurs when the user clicks the export button and the request to export the tube to Traction is successful.
 *    - The component polls Traction to check if the tube is exported successfully.
 *    - If the polling is successful, the component transitions to the TUBE_EXPORT_SUCCESS state.
 *    - If the polling fails, the component transitions to the FAILURE_POLL_TUBE state.
 *
 * 5. TUBE_EXPORT_SUCCESS
 *    - This state occurs if the polling is successful.
 *    - The export button will be disabled.
 *
 * 6. FAILURE_POLL_TUBE
 *    - This state occurs if the polling fails.
 *    - The component provides a button to retry polling.
 *    - If the retry fails, the component transitions to the FAILURE_EXPORT_TUBE_AFTER_RECHECK state.
 *
 * 7. FAILURE_EXPORT_TUBE_AFTER_RECHECK
 *    - This state occurs if the retry after polling failure fails.
 *    - The component allows the user to try exporting the tube again.
 */

import ReadyIcon from '../../icons/ReadyIcon.vue'
import SuccessIcon from '../../icons/SuccessIcon.vue'
import ErrorIcon from '../../icons/ErrorIcon.vue'
import TubeSearchIcon from '../../icons/TubeSearchIcon.vue'
import TubeIcon from '../../icons/TubeIcon.vue'

const maxPollttempts = 10
const pollInterval = 1000

/**
 * Enum for the possible states of the component
 */
const StateEnum = {
  INITIAL: 'initial', // The default state or the initial state when component is first loaded
  CHECKING_TUBE_EXISTS: 'fetching', // The state when the component is checking if the tube exists in Traction on mount
  TUBE_ALREADY_EXPORTED: 'tube_exists', // The state when the component finds the tube in Traction on mount
  POLLING_TUBE: 'polling', // The state when the component is polling Traction to check if the tube is exported
  TUBE_EXPORT_SUCESS: 'tube_export_success', // The state when the tube is successfully exported to Traction
  FAILURE_POLL_TUBE: 'failure_poll_tube', // The state when the component fails to poll Traction for the tube
  FAILURE_EXPORT_TUBE: 'failure_export_tube', // The state when the component fails to export the tube to Traction
  FAILURE_EXPORT_TUBE_AFTER_RECHECK: 'failure_export_tube_after_recheck', // The state when the component fails to export the tube to Traction after rechecking
  INVALID_PROPS: 'invalid_props', // The state when the component receives invalid props
}

/**
 * Data for the different states of the component
 */
const StateData = {
  [StateEnum.INITIAL]: {
    statusText: 'Ready to export',
    buttonText: 'Export',
    styles: { button: 'success', text: 'text-success', icon: 'green' },
    icon: ReadyIcon,
  },
  [StateEnum.CHECKING_TUBE_EXISTS]: {
    statusText: 'Checking tube is in Traction',
    buttonText: 'Please wait',
    styles: { button: 'success', text: 'text-black', icon: 'black' },
    icon: TubeSearchIcon,
  },
  [StateEnum.TUBE_ALREADY_EXPORTED]: {
    statusText: 'Tube already exported to Traction',
    buttonText: 'Open Traction',
    styles: { button: 'success', text: 'text-success', icon: 'green' },
    icon: SuccessIcon,
  },
  [StateEnum.POLLING_TUBE]: {
    statusText: 'Tube is being exported to Traction',
    buttonText: 'Please wait',
    styles: { button: 'success', text: 'text-black', icon: 'black' },
    icon: TubeIcon,
  },
  [StateEnum.TUBE_EXPORT_SUCESS]: {
    statusText: 'Tube has been exported to Traction',
    buttonText: 'Open Traction',
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
    styles: { button: 'warning', text: 'text-warning', icon: 'orange' },
    icon: ErrorIcon,
  },
  [StateEnum.FAILURE_EXPORT_TUBE_AFTER_RECHECK]: {
    statusText: 'Unable to send tube to Traction',
    buttonText: 'Export',
    styles: { button: 'primary', text: 'text-danger', icon: 'red' },
    icon: ErrorIcon,
  },
  [StateEnum.INVALID_PROPS]: {
    statusText: 'Required props are missing',
    buttonText: 'Export',
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
      return this.state === StateEnum.POLLING_TUBE || this.state === StateEnum.CHECKING_TUBE_EXISTS
    },
    sequencescapeApiExportUrl() {
      return `${this.sequencescapeApiUrl}/bioscan/export_pool_xp_to_traction`
    },
    tractionTubeCheckUrl() {
      if (!this.barcode || !this.tractionServiceUrl) return ''
      return `${this.tractionServiceUrl}/pacbio/tubes?filter[barcode]=${this.barcode}`
    },
    tractionTubeOpenUrl() {
      if (!this.barcode || !this.tractionUIUrl) return ''
      return `${this.tractionUIUrl}/pacbio/libraries?filter_value=barcode&filter_input=${this.barcode}`
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

  /**
   * On mount, check if the tube is already exported to Traction
   */
  async mounted() {
    this.validateProps()
    if (this.state === StateEnum.INVALID_PROPS) return
    this.state = StateEnum.CHECKING_TUBE_EXISTS
    const isTubeFound = await this.isTubeInTraction()
    this.state = isTubeFound ? StateEnum.TUBE_ALREADY_EXPORTED : StateEnum.INITIAL
  },
  methods: {
    /**
     * Validate the props
     */
    validateProps() {
      if (!(this.barcode && this.userId && this.sequencescapeApiUrl && this.tractionServiceUrl)) {
        this.state = StateEnum.INVALID_PROPS
        return
      }
    },
    /**
     * Check if the tube is in Traction
     */
    async isTubeInTraction() {
      let isTubeFound = false
      try {
        const response = await fetch(this.tractionTubeCheckUrl)

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

    /**
     * Handle the submit button click
     * The action taken depends on the current state of the component
     *
     * - If the submit button is clicked in the FAILURE_POLL_TUBE state (after polling fails post-submission), the component will check if the tube exists in Traction.
     * - If the submit button is clicked in the TUBE_EXPORT_SUCCESS state (after successful export), the component will open the tube in Traction.
     * - In all other states, clicking the submit button will submit the tube to Traction.
     */
    async handleSubmit() {
      switch (this.state) {
        case StateEnum.FAILURE_POLL_TUBE: {
          this.state = StateEnum.CHECKING_TUBE_EXISTS
          const isFound = await this.isTubeInTraction()
          this.state = isFound ? StateEnum.TUBE_EXPORT_SUCESS : StateEnum.FAILURE_EXPORT_TUBE_AFTER_RECHECK
          return
        }
        case StateEnum.TUBE_EXPORT_SUCESS:
        case StateEnum.TUBE_ALREADY_EXPORTED: {
          // Open Traction in a new tab
          window.open(this.tractionTubeOpenUrl, '_blank')
          return
        }
        default: {
          await this.exportTubeToTraction()
          return
        }
      }
    },
    /**
     * Export the tube to Traction and poll Traction for the tube status if the export is successful
     */
    async exportTubeToTraction() {
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
          await this.pollTractionForTube()
        } else {
          this.state = StateEnum.FAILURE_EXPORT_TUBE
        }
      } catch (error) {
        console.error('Error submitting tube to Traction:', error)
        this.state = StateEnum.FAILURE_EXPORT_TUBE
      }
    },

    /**
     * Poll Traction for the tube status
     * If the tube is found, the component transitions to the TUBE_EXPORT_SUCCESS state
     * If the tube is not found, the component retries polling after a delay until the maximum number of attempts is reached
     */
    async pollTractionForTube() {
      let attempts = 0

      const poll = async () => {
        if (attempts > +maxPollttempts) {
          this.state = StateEnum.FAILURE_POLL_TUBE
          return
        }
        const isTubeFound = await this.isTubeInTraction()
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
