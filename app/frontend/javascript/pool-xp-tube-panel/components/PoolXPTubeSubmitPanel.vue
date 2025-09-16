<template>
  <div class="d-flex justify-content-between align-items-center">
    <label
      id="pool_xp_tube_export_status"
      :class="['p-2', 'mt-2', stateStyles.text]"
      :style="{ fontSize: '1.0rem', display: 'flex', alignItems: 'center' }"
    >
      <b-spinner v-show="displaySpinner" id="progress_spinner" small type="border" class="me-2" />
      <component :is="statusIcon" id="status_icon" class="me-1" :color="stateStyles.icon" />
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
 * @property {String} sequencescapeApi - The URL of the Sequencescape API
 * @property {String} tractionServiceUrl - The URL of the Traction service
 * @property {String} tractionUiUrl - The URL of the Traction UI
 *
 * This component exports a tube to Traction and polls Traction to check if the tube is exported successfully.
 * This is performed in two steps:
 * - Export the tube to Traction using the Sequencescape API (export_pool_xp_to_traction) endpoint
 * - Poll Traction to check if the tube is exported successfully using the Traction API (GET /pacbio/tubes?filter[barcode]=<barcode>)
 *
 * The component has the following states:
 *
 * State 1: CHECKING_TUBE_STATUS
 *    When the component is first loaded, it is in the CHECKING_TUBE_STATUS state.
 *    The components displays a spinner and a message indicating that it is checking if the tube is in Traction. The button is disabled.
 *    Transition:
 *    - If the tube is not found, the component remains in the State 2 (READY_TO_EXPORT) state.
 *    - If the tube is found, the component transitions to the State 6 (TUBE_ALREADY_EXPORTED).
 *    - If the service is unavailable or returns error, the component transitions to the State 4 (FAILURE_TUBE_CHECK) state.
 *
 * State 2: READY_TO_EXPORT
 *     This state occurs if the tube is found in Traction during the State 1.
 *     The component provides a button to export tube to Traction. Clicking the button transitions the component as follows
 *     Transition:
 *      - If the export using Sequencescape API is successful, the component transitions to the State 3 (EXPORTING_TUBE) state.
 *      - If the export using Sequencescape API fails, the component transitions to the State 8 (FAILURE_EXPORT_TUBE) state.
 *      - If the tube is found in Traction after the export, the component transitions to the State 5 (TUBE_EXPORT_SUCCESS) state.
 *      - If the tube is not found in Traction after the export, the component transitions to the State 7 (FAILURE_TUBE_CHECK_AFTER_EXPORT) state.
 *
 * State 3: EXPORTING_TUBE
 *   This state occurs when the user clicks the export button and the request to export Sequencescape SS API is successful.
 *   At this state, the component polls Traction using Traction API to check if the tube is exported successfully.
 *   The component displays a spinner and a message indicating that the tube is being exported to Traction. The button is disabled.
 *   Transition:
 *      - If the polling is successful, the component transitions to the State 5 (TUBE_EXPORT_SUCCESS) state.
 *      - If the polling fails, the component transitions to the State 7 (FAILURE_TUBE_CHECK_AFTER_EXPORT) state.
 *
 * State 4: FAILURE_TUBE_CHECK
 *   This state occurs if the initial check to see if the tube is in Traction fails.
 *   The component provides a button to retry checking if the tube is in Traction and a message indicating that the export cannot be verified.
 *   On clicking the button, the component perfors same operation as in State 1.
 *   Transition:
 *     - The component transitions to the State 1 (CHECKING_TUBE_STATUS) state.
 *
 * State 5: TUBE_EXPORT_SUCCESS
 * This state occurs if the exporting the tube using Sequencescape API is successful and the polling using Traction API is successful.
 * The component displays a message indicating that the tube has been exported to Traction and an open Traction button to open the tube in Traction is displayed.
 * Transition:
 *    - If the user clicks the open Traction button, the component opens the tube in Traction.
 *
 * State 6: TUBE_ALREADY_EXPORTED
 * This state occurs if the initial check tube to see if the tube is in Traction returns a tube.
 * The component displays a message indicating that the tube is already exported to Traction and an open Traction button to open the tube in Traction is displayed.
 * Transition:
 *   - If the user clicks the open Traction button, the component opens the tube in Traction.
 *
 * State 7: FAILURE_TUBE_CHECK_AFTER_EXPORT
 * This state occurs if the exporting the tube using Sequencescape API is successful but the polling using Traction API fails.
 * The component provides a button to retry polling and a message indicating that the export cannot be verified.
 * Transition:
 *   - When retry button is clicked, the component transitions to the State 3 (EXPORTING_TUBE) state.
 *
 * State 8: FAILURE_EXPORT_TUBE
 * This state occurs if the exporting the tube using Sequencescape API fails.
 * The component provides a button to retry exporting the tube and a message indicating that the tube export to Traction failed.
 * Transition:
 *  - When retry button is clicked, the component transitions to the State 3 (EXPORTING_TUBE) state.
 *
 * State 9: INVALID_PROPS
 * This state occurs if the required props are missing when the component is mounted.
 * The component provides a message indicating that the required props are missing and the button is disabled.
 */

import ReadyIcon from '../../icons/ReadyIcon.vue'
import SuccessIcon from '../../icons/SuccessIcon.vue'
import ErrorIcon from '../../icons/ErrorIcon.vue'
import TubeSearchIcon from '../../icons/TubeSearchIcon.vue'
import TubeIcon from '../../icons/TubeIcon.vue'

const DEFAULT_MAX_TUBE_CHECK_RETRIES = 3
const DEFAULT_MAX_TUBE_CHECK_RETRY_DELAY = 1000

/**
 * Enum for the possible states of the component
 */
const StateEnum = {
  READY_TO_EXPORT: 'ready_to_export', // The state when the component is ready to export the tube
  CHECKING_TUBE_STATUS: 'checking_tube_status', // The state when the component is checking if the tube is in Traction and this is the initial state as well
  TUBE_ALREADY_EXPORTED: 'tube_exists', // The state when the tube is already exported to Traction
  EXPORTING_TUBE: 'exporting', // The state when the component is exporting the tube to Traction
  TUBE_EXPORT_SUCESS: 'tube_export_success', // The state when the tube is successfully exported to Traction
  FAILURE_TUBE_CHECK: 'failure_tube_check', // The state when the component fails to check if the tube is in Traction using the Traction API
  FAILURE_TUBE_CHECK_AFTER_EXPORT: 'failure_tube_check_export', // The state when the component fails to check if the tube is in Traction after exporting using the Traction API
  FAILURE_EXPORT_TUBE: 'failure_export_tube', // The state when the component fails to export the tube when the export (SS API) fails
  INVALID_PROPS: 'invalid_props', // The state when the component receives invalid props
}

/**
 * Data for the different states of the component
 */
const StateData = {
  [StateEnum.CHECKING_TUBE_STATUS]: {
    statusText: 'Checking tube is in Traction',
    buttonText: 'Please wait',
    styles: { button: 'success', text: 'text-black', icon: 'black' },
    icon: TubeSearchIcon,
  },
  [StateEnum.READY_TO_EXPORT]: {
    statusText: 'Ready to export',
    buttonText: 'Export',
    styles: { button: 'success', text: 'text-success', icon: 'green' },
    icon: ReadyIcon,
  },
  [StateEnum.TUBE_ALREADY_EXPORTED]: {
    statusText: 'Tube already exported to Traction',
    buttonText: 'Open Traction',
    styles: { button: 'primary', text: 'text-success', icon: 'green' },
    icon: SuccessIcon,
  },

  [StateEnum.EXPORTING_TUBE]: {
    statusText: 'Tube is being exported to Traction',
    buttonText: 'Please wait',
    styles: { button: 'success', text: 'text-black', icon: 'black' },
    icon: TubeIcon,
  },
  [StateEnum.TUBE_EXPORT_SUCESS]: {
    statusText: 'Tube has been exported to Traction',
    buttonText: 'Open Traction',
    styles: { button: 'primary', text: 'text-success', icon: 'green' },
    icon: SuccessIcon,
  },
  [StateEnum.FAILURE_TUBE_CHECK]: {
    statusText: 'The export cannot be verified. Refresh to try again',
    buttonText: 'Refresh',
    styles: { button: 'danger', text: 'text-danger', icon: 'red' },
    icon: ErrorIcon,
  },
  [StateEnum.FAILURE_TUBE_CHECK_AFTER_EXPORT]: {
    statusText:
      'The export process to Traction has been initiated. Verification may take a few seconds to complete, depending on factors like network speed. Please revisit or refresh the page after 10 minutes.',
    buttonText: 'Refresh',
    styles: { button: 'primary', text: 'text-primary', icon: 'blue' },
    icon: ErrorIcon,
  },
  [StateEnum.FAILURE_EXPORT_TUBE]: {
    statusText: 'The tube export to Traction failed. Try again',
    buttonText: 'Try again',
    styles: { button: 'danger', text: 'text-danger', icon: 'red' },
    icon: ErrorIcon,
  },
  [StateEnum.INVALID_PROPS]: {
    statusText: 'Required props are missing',
    buttonText: 'Export',
    styles: { button: 'danger', text: 'text-danger', icon: 'red' },
    icon: ErrorIcon,
  },
}

/**
 * Enum for the possible results of the tube search using the Traction API
 */
const TubeSearchResult = {
  FOUND: 'found',
  NOT_FOUND: 'not_found',
  SERVICE_ERROR: 'service_error',
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
    sequencescapeApi: {
      type: String,
      required: true,
    },
    tractionServiceUrl: {
      type: String,
      required: true,
    },
    tractionUiUrl: {
      type: String,
      required: true,
    },
  },
  data: function () {
    return {
      state: StateEnum.CHECKING_TUBE_STATUS,
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
      return StateData[this.state]?.styles || { button: 'danger', text: 'text-danger', icon: 'red' }
    },
    statusIcon() {
      return StateData[this.state].icon
    },

    isButtonDisabled() {
      return (
        this.state === StateEnum.CHECKING_TUBE_STATUS ||
        this.state === StateEnum.EXPORTING_TUBE ||
        this.state === StateEnum.INVALID_PROPS
      )
    },
    displaySpinner() {
      return this.state === StateEnum.EXPORTING_TUBE || this.state === StateEnum.CHECKING_TUBE_STATUS
    },
    sequencescapeApiExportUrl() {
      return `${this.sequencescapeApi}/bioscan/export_pool_xp_to_traction`
    },
    tractionTubeCheckUrl() {
      if (!this.barcode || !this.tractionServiceUrl) return ''
      return `${this.tractionServiceUrl}/pacbio/tubes?filter[barcode]=${this.barcode}`
    },
    tractionTubeOpenUrl() {
      if (!this.barcode || !this.tractionUiUrl) return ''
      return `${this.tractionUiUrl}/#/pacbio/libraries?filter_value=source_identifier&filter_input=${this.barcode}`
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
   * If the tube is found, transition to the TUBE_ALREADY_EXPORTED state
   * If the tube is not found, transition to the INITIAL state
   * If the service is unavailable or returns error, transition to the FAILURE_TUBE_CHECK state
   */
  async mounted() {
    // Validate the props
    this.validateProps()
    if (this.state === StateEnum.INVALID_PROPS) return
    this.initialiseStartState()
  },
  methods: {
    /**
     * Validate the props
     */
    validateProps() {
      if (!(this.barcode && this.sequencescapeApi && this.tractionServiceUrl && this.tractionUiUrl)) {
        this.state = StateEnum.INVALID_PROPS
        return
      }
    },

    /**
     * Check if the tube is in Traction
     * @returns {TubeSearchResult} - The result of the tube search
     * - FOUND: If the tube is found in Traction
     * - NOT_FOUND: If the tube is not found in Traction
     * - SERVICE_ERROR: If the service is unavailable or returns error
     */
    async checkTubeInTraction() {
      try {
        const response = await fetch(this.tractionTubeCheckUrl)
        if (response.ok) {
          const data = await response.json()
          if (data.data && data.data.length > 0) {
            return TubeSearchResult.FOUND
          }
          return TubeSearchResult.NOT_FOUND
        } else {
          console.log('Fetch response not ok:', response.statusText)
          return TubeSearchResult.SERVICE_ERROR
        }
      } catch (error) {
        console.log('Error during fetch:', error)
        return TubeSearchResult.SERVICE_ERROR
      }
    },

    /**
     * Initialise the start state of the component
     * - Check if the tube is already exported to Traction and transition to the appropriate state based on the result
     * - If the tube is found in Traction, transition to the TUBE_ALREADY_EXPORTED state
     * - If the service is unavailable or returns error, transition to the FAILURE_TUBE_CHECK state
     * - If the tube is not found in Traction, transition to the INITIAL state which allows the user to export the tube
     */
    async initialiseStartState() {
      this.state = StateEnum.CHECKING_TUBE_STATUS
      const result = await this.checkTubeStatusWithRetries()

      // If the tube is found in Traction, transition to the TUBE_ALREADY_EXPORTED state
      if (result === TubeSearchResult.FOUND) {
        this.state = StateEnum.TUBE_ALREADY_EXPORTED
        return
      }
      // If the service is unavailable or returns error, transition to the FAILURE_TUBE_CHECK state
      if (result === TubeSearchResult.SERVICE_ERROR) {
        this.state = StateEnum.FAILURE_TUBE_CHECK
        return
      }
      // If the tube is not found in Traction, transition to the INITIAL state which allows the user to export the tube
      this.state = StateEnum.READY_TO_EXPORT
    },

    /**
     * Handle the submit button click
     * The action taken depends on the current state of the component
     *
     * - If the state is FAILURE_TUBE_CHECK, it means the initial check failed, therefore repeat the initial check
     * - If the state is TUBE_EXPORT_SUCESS or TUBE_ALREADY_EXPORTED, open the tube in Traction
     * - Otherwise, export the tube to Traction
     * */
    async handleSubmit() {
      switch (this.state) {
        case StateEnum.FAILURE_TUBE_CHECK: {
          this.initialiseStartState()
          break
        }
        case StateEnum.TUBE_EXPORT_SUCESS:
        case StateEnum.TUBE_ALREADY_EXPORTED: {
          // Open Traction in a new tab
          window.open(this.tractionTubeOpenUrl, '_blank')
          break
        }

        default: {
          await this.exportTubeToTraction()
          break
        }
      }
    },
    /**
     * Export the tube to Traction and poll Traction for the tube status if the export is successful
     *
     * - If the export api is successful, transition to the EXPORTING_TUBE state and poll Traction for the tube status
     * - If the export api fails, transition to the FAILURE_EXPORT_TUBE state which allows the user to retry exporting the tube
     * - If the tube is found in Traction after the export, transition to the TUBE_EXPORT_SUCCESS state which allows the user to open the tube in Traction
     * - If the tube is not found in Traction after the export, transition to the FAILURE_TUBE_CHECK_AFTER_EXPORT state which allows the user to retry exporting the tube
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
          this.state = StateEnum.EXPORTING_TUBE
          const retStatus = await this.checkTubeStatusWithRetries(DEFAULT_MAX_TUBE_CHECK_RETRIES + 2)
          this.state =
            retStatus === TubeSearchResult.FOUND
              ? StateEnum.TUBE_EXPORT_SUCESS
              : StateEnum.FAILURE_TUBE_CHECK_AFTER_EXPORT
          return
        } else {
          this.state = StateEnum.FAILURE_EXPORT_TUBE
        }
      } catch (error) {
        console.log('Error exporting tube to Traction:', error)
        this.state = StateEnum.FAILURE_EXPORT_TUBE
      }
    },

    /**
     * Check the tube status with retries
     * @param {number} retries - Number of retries
     * @param {number} delay - Delay between retries in milliseconds
     */
    async checkTubeStatusWithRetries(
      retries = DEFAULT_MAX_TUBE_CHECK_RETRIES,
      delay = DEFAULT_MAX_TUBE_CHECK_RETRY_DELAY,
    ) {
      let result = TubeSearchResult.NOT_FOUND
      for (let i = 0; i < retries; i++) {
        result = await this.checkTubeInTraction()
        if (result === TubeSearchResult.FOUND) {
          return result
        }
        if (i < retries - 1) {
          await this.sleep(delay)
        }
      }

      return result
    },

    /**
     * Sleep for a specified duration
     * @param {number} ms - Duration in milliseconds
     * @returns {Promise}
     */
    sleep(ms) {
      return new Promise((resolve) => setTimeout(resolve, ms))
    },
  },
}
</script>
