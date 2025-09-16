import { mount } from '@vue/test-utils'
import PoolXPTubeSubmitPanel from './PoolXPTubeSubmitPanel.vue'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { flushPromises } from '@vue/test-utils'
import ReadyIcon from '../../icons/ReadyIcon.vue'
import TubeSearchIcon from '../../icons/TubeSearchIcon.vue'
import SuccessIcon from '../../icons/SuccessIcon.vue'
import ErrorIcon from '../../icons/ErrorIcon.vue'
import TubeIcon from '../../icons/TubeIcon.vue'

// Default props
const defaultProps = {
  barcode: '12345',
  userId: 'user123',
  sequencescapeApi: 'http://example.com/api',
  tractionServiceUrl: 'http://traction.example.com',
  tractionUiUrl: 'http://traction-ui.example.com',
}

// Helper function to create the wrapper with the given state and props
const createWrapper = (state = 'checking_tube_status', props = { ...defaultProps }) => {
  return mount(PoolXPTubeSubmitPanel, {
    props: {
      ...props,
    },
    data() {
      return {
        state,
      }
    },
  })
}

// Helper function to mock fetch responses sequentially
const mockFetch = (responses) => {
  const fetchMock = vi.spyOn(global, 'fetch')
  responses.forEach((response) => {
    fetchMock.mockImplementationOnce(() =>
      Promise.resolve({
        ok: response.ok,
        json: () => Promise.resolve(response.data),
      }),
    )
  })
  return fetchMock
}

//Response objects
const emptyResponse = { ok: true, data: { data: [] } } // Initial successful response
const failedResponse = { ok: false, data: { error: 'API call failed' } } // Subsequent failure response
const successResponse = { ok: true, data: { data: [{ id: '1' }] } } // Subsequent success response

const mockTubeFoundResponse = () => {
  vi.spyOn(global, 'fetch').mockImplementation(() =>
    Promise.resolve({
      ok: true,
      json: () => Promise.resolve({ ...successResponse.data }),
    }),
  )
}
const mockTubeCheckFailureResponse = () => {
  vi.spyOn(global, 'fetch').mockImplementation(() =>
    Promise.resolve({
      ok: false,
      json: () => Promise.resolve({ ...failedResponse.data }),
    }),
  )
}

const mockNoTubeFoundResponse = () => {
  vi.spyOn(global, 'fetch').mockImplementation(() =>
    Promise.resolve({
      ok: true,
      json: () => Promise.resolve({ ...emptyResponse.data }),
    }),
  )
}

// Helper function to check if the component displays the correct state as per the given state value
const verifyComponentState = (wrapper, state) => {
  const exportButton = wrapper.find('#pool_xp_tube_export_button')
  const statusLabel = wrapper.find('#pool_xp_tube_export_status')
  const spinner = wrapper.find('#progress_spinner')
  const statusIcon = wrapper.find('#status_icon')
  switch (state) {
    case 'ready_to_export': {
      expect(exportButton.exists()).toBe(true)
      expect(statusLabel.exists()).toBe(true)
      expect(spinner.isVisible()).toBe(false)
      expect(statusIcon.isVisible()).toBe(true)
      expect(exportButton.element.disabled).toBe(false)
      expect(exportButton.classes()).toContain('btn-success')
      expect(statusLabel.classes()).toContain('text-success')
      expect(statusLabel.text()).toBe('Ready to export')
      expect(exportButton.text()).toBe('Export')
      const iconComponent = statusIcon.findComponent(ReadyIcon)
      expect(iconComponent.exists()).toBe(true)
      expect(iconComponent.props().color).toBe('green')
      break
    }

    case 'checking_tube_status': {
      expect(exportButton.exists()).toBe(true)
      expect(statusLabel.exists()).toBe(true)
      expect(spinner.isVisible()).toBe(true)
      expect(statusIcon.isVisible()).toBe(true)
      expect(exportButton.element.disabled).toBe(true)
      expect(exportButton.classes()).toContain('btn-success')
      expect(statusLabel.classes()).toContain('text-black')
      expect(statusLabel.text()).toBe('Checking tube is in Traction')
      expect(exportButton.text()).toBe('Please wait')
      const iconComponent = statusIcon.findComponent(TubeSearchIcon)
      expect(iconComponent.exists()).toBe(true)
      expect(iconComponent.props().color).toContain('black')
      break
    }

    case 'tube_exists': {
      expect(exportButton.exists()).toBe(true)
      expect(statusLabel.exists()).toBe(true)
      expect(spinner.isVisible()).toBe(false)
      expect(statusIcon.isVisible()).toBe(true)
      expect(exportButton.element.disabled).toBe(false)
      expect(exportButton.classes()).toContain('btn-primary')
      expect(statusLabel.classes()).toContain('text-success')
      expect(statusLabel.text()).toBe('Tube already exported to Traction')
      expect(exportButton.text()).toBe('Open Traction')
      const iconComponent = statusIcon.findComponent(SuccessIcon)
      expect(iconComponent.exists()).toBe(true)
      expect(iconComponent.props().color).toContain('green')
      break
    }

    case 'exporting': {
      expect(exportButton.exists()).toBe(true)
      expect(statusLabel.exists()).toBe(true)
      expect(spinner.isVisible()).toBe(true)
      expect(statusIcon.isVisible()).toBe(true)
      expect(exportButton.element.disabled).toBe(true)
      expect(exportButton.classes()).toContain('btn-success')
      expect(statusLabel.classes()).toContain('text-black')
      expect(statusLabel.text()).toBe('Tube is being exported to Traction')
      expect(exportButton.text()).toBe('Please wait')
      const iconComponent = statusIcon.findComponent(TubeIcon)
      expect(iconComponent.exists()).toBe(true)
      expect(iconComponent.props().color).toContain('black')
      break
    }

    case 'tube_export_success': {
      expect(exportButton.exists()).toBe(true)
      expect(statusLabel.exists()).toBe(true)
      expect(spinner.isVisible()).toBe(false)
      expect(statusIcon.isVisible()).toBe(true)
      expect(exportButton.element.disabled).toBe(false)
      expect(exportButton.classes()).toContain('btn-primary')
      expect(statusLabel.classes()).toContain('text-success')
      expect(statusLabel.text()).toBe('Tube has been exported to Traction')
      expect(exportButton.text()).toBe('Open Traction')
      const iconComponent = statusIcon.findComponent(SuccessIcon)
      expect(iconComponent.exists()).toBe(true)
      expect(iconComponent.props().color).toContain('green')
      break
    }

    case 'failure_export_tube': {
      expect(exportButton.exists()).toBe(true)
      expect(statusLabel.exists()).toBe(true)
      expect(spinner.isVisible()).toBe(false)
      expect(statusIcon.isVisible()).toBe(true)
      expect(exportButton.element.disabled).toBe(false)
      expect(exportButton.classes()).toContain('btn-danger')
      expect(statusLabel.classes()).toContain('text-danger')
      expect(statusLabel.text()).toBe('The tube export to Traction failed. Try again')
      expect(exportButton.text()).toBe('Try again')
      const iconComponent = statusIcon.findComponent(ErrorIcon)
      expect(iconComponent.exists()).toBe(true)
      expect(iconComponent.props().color).toContain('red')
      break
    }

    case 'failure_tube_check': {
      expect(exportButton.exists()).toBe(true)
      expect(statusLabel.exists()).toBe(true)
      expect(spinner.isVisible()).toBe(false)
      expect(statusIcon.isVisible()).toBe(true)
      expect(exportButton.element.disabled).toBe(false)
      expect(exportButton.classes()).toContain('btn-danger')
      expect(statusLabel.classes()).toContain('text-danger')
      expect(statusLabel.text()).toBe('The export cannot be verified. Refresh to try again')
      expect(exportButton.text()).toBe('Refresh')
      const iconComponent = statusIcon.findComponent(ErrorIcon)
      expect(iconComponent.exists()).toBe(true)
      expect(iconComponent.props().color).toContain('red')
      break
    }

    case 'failure_tube_check_export': {
      expect(exportButton.exists()).toBe(true)
      expect(statusLabel.exists()).toBe(true)
      expect(spinner.isVisible()).toBe(false)
      expect(statusIcon.isVisible()).toBe(true)
      expect(exportButton.element.disabled).toBe(false)
      expect(exportButton.classes()).toContain('btn-primary')
      expect(statusLabel.classes()).toContain('text-primary')
      expect(statusLabel.text()).toBe(
        'The export process to Traction has been initiated. Verification may take a few seconds to complete, depending on factors like network speed. Please revisit or refresh the page after 10 minutes.',
      )
      expect(exportButton.text()).toBe('Refresh')
      const iconComponent = statusIcon.findComponent(ErrorIcon)
      expect(iconComponent.exists()).toBe(true)
      expect(iconComponent.props().color).toContain('blue')
      break
    }

    case 'invalid_props': {
      expect(exportButton.exists()).toBe(true)
      expect(statusLabel.exists()).toBe(true)
      expect(spinner.isVisible()).toBe(false)
      expect(statusIcon.isVisible()).toBe(true)
      expect(exportButton.element.disabled).toBe(true)
      expect(exportButton.classes()).toContain('btn-danger')
      expect(statusLabel.classes()).toContain('text-danger')
      expect(statusLabel.text()).toBe('Required props are missing')
      expect(exportButton.text()).toBe('Export')
      const iconComponent = statusIcon.findComponent(ErrorIcon)
      expect(iconComponent.exists()).toBe(true)
      expect(iconComponent.props().color).toContain('red')
      break
    }
  }
}

describe('PoolXPTubeSubmitPanel', () => {
  let wrapper

  beforeEach(() => {
    mockNoTubeFoundResponse()
    vi.spyOn(console, 'log').mockImplementation(() => {})
    vi.spyOn(window, 'open').mockImplementation(() => {})
  })

  it('renders the component', () => {
    wrapper = createWrapper()
    expect(wrapper.exists()).toBe(true)
  })

  it.each([
    'ready_to_export',
    'checking_tube_status',
    'tube_exists',
    'exporting',
    'tube_export_success',
    'failure_export_tube',
    'failure_tube_check',
    'failure_tube_check_export',
    'invalid_props',
  ])('displays the correct status based on %s state', (stateValue) => {
    const wrapper = createWrapper(stateValue)
    verifyComponentState(wrapper, stateValue)
  })

  describe('methods', () => {
    describe('initialiseStartState', () => {
      let wrapper
      beforeEach(async () => {
        wrapper = createWrapper()
        // Mock the sleep function to resolve immediately
        wrapper.vm.sleep = vi.fn().mockImplementation(() => Promise.resolve())
        await flushPromises()
      })
      it('transitions to TUBE_ALREADY_EXPORTED state when tube is found', async () => {
        // Mock the fetch response to indicate a tube is found
        mockTubeFoundResponse()

        // Call initialiseStartState
        await wrapper.vm.initialiseStartState()
        await flushPromises()

        // Check the state after initialiseStartState
        expect(wrapper.vm.state).toBe('tube_exists')
      })

      it('transitions to FAILURE_TUBE_CHECK state when service error occurs', async () => {
        // Mock the fetch response to indicate a service error
        mockTubeCheckFailureResponse()

        // Call initialiseStartState
        await wrapper.vm.initialiseStartState()
        await flushPromises()

        // Check the state after initialiseStartState
        expect(wrapper.vm.state).toBe('failure_tube_check')
      })

      it('transitions to READY_TO_EXPORT state when no tube is found', async () => {
        // Mock the fetch response to indicate no tube is found
        mockNoTubeFoundResponse()

        // Call initialiseStartState
        await wrapper.vm.initialiseStartState()
        await flushPromises()

        // Check the state after initialiseStartState
        expect(wrapper.vm.state).toBe('ready_to_export')
      })
    })

    describe('checkTubeInTraction', () => {
      let wrapper
      beforeEach(async () => {
        wrapper = createWrapper()
        // Mock the sleep function to resolve immediately
        wrapper.vm.sleep = vi.fn().mockImplementation(() => Promise.resolve())
        await flushPromises()
      })

      it('returns "found" when tube is found', async () => {
        // Mock the fetch response to indicate the tube is found
        mockTubeFoundResponse()
        const result = await wrapper.vm.checkTubeInTraction()
        expect(result).toBe('found')
      })

      it('returns "not_found" when no tube is found', async () => {
        // Mock the fetch response to indicate no tube is found
        mockNoTubeFoundResponse()
        const result = await wrapper.vm.checkTubeInTraction()
        expect(result).toBe('not_found')
      })

      it('returns "service_error" when response is not ok', async () => {
        // Mock the fetch response to indicate a service error
        mockTubeCheckFailureResponse()
        const result = await wrapper.vm.checkTubeInTraction()
        expect(result).toBe('service_error')
      })

      it('returns "service_error" when an exception is thrown', async () => {
        // Mock the fetch to throw an error
        vi.spyOn(global, 'fetch').mockImplementationOnce(() => Promise.reject(new Error('Network error')))

        const result = await wrapper.vm.checkTubeInTraction()
        expect(result).toBe('service_error')
      })
    })

    describe('checkTubeStatusWithRetries', () => {
      let wrapper
      beforeEach(async () => {
        wrapper = createWrapper()
        wrapper.vm.sleep = vi.fn().mockImplementation(() => Promise.resolve())
        await flushPromises()
      })
      it('calls checkTubeStatusWithRetries once when tube is found on first try', async () => {
        // Mock the fetch response to indicate the tube is found on the first try
        vi.spyOn(wrapper.vm, 'checkTubeInTraction').mockImplementationOnce(() => Promise.resolve('found'))

        const result = await wrapper.vm.checkTubeStatusWithRetries()
        expect(result).toBe('found')
        expect(wrapper.vm.checkTubeInTraction).toHaveBeenCalledTimes(1)
      })

      it('calls checkTubeStatusWithRetries multiple times when tube is found after retries', async () => {
        // Mock the fetch response to indicate the tube is found after some retries
        vi.spyOn(wrapper.vm, 'checkTubeInTraction')
          .mockImplementationOnce(() => Promise.resolve('not_found'))
          .mockImplementationOnce(() => Promise.resolve('not_found'))
          .mockImplementationOnce(() => Promise.resolve('found'))

        const result = await wrapper.vm.checkTubeStatusWithRetries(5, 1000)
        expect(result).toBe('found')
        expect(wrapper.vm.checkTubeInTraction).toHaveBeenCalledTimes(3)
      })

      it('calls checkTubeStatusWithRetries the maximum number of retries when tube is not found', async () => {
        // Mock the fetch response to indicate no tube is found after all retries
        vi.spyOn(wrapper.vm, 'checkTubeInTraction').mockImplementation(() => Promise.resolve('not_found'))

        const result = await wrapper.vm.checkTubeStatusWithRetries(3, 1000)
        expect(result).toBe('not_found')
        expect(wrapper.vm.checkTubeInTraction).toHaveBeenCalledTimes(3)
      })

      it('calls checkTubeStatusWithRetries once when service error occurs', async () => {
        // Mock the fetch response to indicate a service error
        vi.spyOn(wrapper.vm, 'checkTubeInTraction').mockImplementation(() => Promise.resolve('service_error'))

        const result = await wrapper.vm.checkTubeStatusWithRetries(3, 1000)
        expect(result).toBe('service_error')
        expect(wrapper.vm.checkTubeInTraction).toHaveBeenCalledTimes(3)
      })
    })
  })

  describe('on Mount', () => {
    it('calls checkTubeInTraction on mount', async () => {
      vi.spyOn(PoolXPTubeSubmitPanel.methods, 'checkTubeInTraction')
      wrapper = createWrapper()
      expect(PoolXPTubeSubmitPanel.methods.checkTubeInTraction).toHaveBeenCalled()
    })

    it('handles invalid props correctly on mount', async () => {
      wrapper = createWrapper('checking_tube_status', {
        barcode: '',
        userId: '',
        sequencescapeApi: '',
        tractionServiceUrl: '',
        tractionUiUrl: 'http://traction-ui.example.com',
      })
      await flushPromises()
      expect(wrapper.vm.state).toBe('invalid_props')
      verifyComponentState(wrapper, 'invalid_props')
    })

    it('handles fetching tube success from Traction correctly on mount', async () => {
      mockTubeFoundResponse()
      wrapper = createWrapper()
      await flushPromises()
      expect(global.fetch).toBeCalledTimes(1)
      expect(global.fetch).toHaveBeenCalledWith(wrapper.vm.tractionTubeCheckUrl)

      expect(wrapper.vm.state).toBe('tube_exists')
      verifyComponentState(wrapper, 'tube_exists')
    })
    it('handles fetching no tubes from Traction correctly on mount', async () => {
      mockNoTubeFoundResponse()
      wrapper = createWrapper()
      wrapper.vm.sleep = vi.fn().mockImplementation(() => Promise.resolve())
      await flushPromises()
      expect(wrapper.vm.state).toBe('ready_to_export')
      verifyComponentState(wrapper, 'ready_to_export')
    })

    it('handles fetching tube failure from Traction correctly on mount', async () => {
      mockTubeCheckFailureResponse()
      wrapper = createWrapper()
      wrapper.vm.sleep = vi.fn().mockImplementation(() => Promise.resolve())
      await flushPromises()
      expect(wrapper.vm.state).toBe('failure_tube_check')
      verifyComponentState(wrapper, 'failure_tube_check')
    })
  })

  describe('Export action', () => {
    describe('When tube is not already exported and component is in ready_to_export  state', () => {
      let originalSleep, wrapper
      beforeEach(async () => {
        mockNoTubeFoundResponse()
        wrapper = createWrapper()
        originalSleep = wrapper.vm.sleep
        // Mock the sleep function to resolve immediately
        wrapper.vm.sleep = vi.fn().mockImplementation(() => Promise.resolve())
        await flushPromises()
      })
      it('dispalys the correct state', () => {
        expect(wrapper.vm.state).toBe('ready_to_export')
        verifyComponentState(wrapper, 'ready_to_export')
      })
      it('immediately transitions to exporting state when export button is clicked', async () => {
        wrapper.vm.sleep = originalSleep
        await wrapper.find('#pool_xp_tube_export_button').trigger('click')
        await flushPromises()
        expect(wrapper.vm.state).toBe('exporting')
      })
      it('transitions state correctly when export is successful', async () => {
        mockTubeFoundResponse()
        await wrapper.find('#pool_xp_tube_export_button').trigger('click')
        await flushPromises()
        expect(wrapper.vm.state).toBe('tube_export_success')
        verifyComponentState(wrapper, 'tube_export_success')

        await wrapper.find('#pool_xp_tube_export_button').trigger('click')
        await flushPromises()
        expect(window.open).toHaveBeenCalledWith(wrapper.vm.tractionTubeOpenUrl, '_blank')
      })
      it('transitions state correctly when no tube exists and export fails', async () => {
        mockTubeCheckFailureResponse()
        await wrapper.find('#pool_xp_tube_export_button').trigger('click')
        await flushPromises()
        expect(wrapper.vm.state).toBe('failure_export_tube')
        verifyComponentState(wrapper, 'failure_export_tube')
      })
      it('transitions states correctly when no tube exists and tube checking using traction api fails', async () => {
        mockFetch([
          emptyResponse, // Initial empty response
          failedResponse, // Subsequent failure response
        ])
        await wrapper.find('#pool_xp_tube_export_button').trigger('click')
        await flushPromises()
        expect(wrapper.vm.state).toBe('failure_tube_check_export')
        verifyComponentState(wrapper, 'failure_tube_check_export')

        mockNoTubeFoundResponse()
        await wrapper.find('#pool_xp_tube_export_button').trigger('click')
        await flushPromises()
        expect(wrapper.vm.state).toBe('failure_tube_check_export')
        verifyComponentState(wrapper, 'failure_tube_check_export')
      })
      it('transitions states correctly when no tube exists and tube checking using traction api succeeds', async () => {
        mockFetch([
          emptyResponse, // Initial empty response
          failedResponse, // Subsequent success response
        ])
        await wrapper.find('#pool_xp_tube_export_button').trigger('click')
        await flushPromises()
        expect(wrapper.vm.state).toBe('failure_tube_check_export')
        verifyComponentState(wrapper, 'failure_tube_check_export')

        mockTubeFoundResponse()
        await wrapper.find('#pool_xp_tube_export_button').trigger('click')
        await flushPromises()
        expect(wrapper.vm.state).toBe('tube_export_success')
        verifyComponentState(wrapper, 'tube_export_success')
      })
    })
    describe('When tube is already exported and component is in tube_exists state', () => {
      let wrapper
      beforeEach(async () => {
        mockTubeFoundResponse()
        wrapper = createWrapper()
        await flushPromises()
      })
      it('dispalys the correct state', () => {
        expect(wrapper.vm.state).toBe('tube_exists')
        verifyComponentState(wrapper, 'tube_exists')
      })
      it('opens Traction in a new tab when open traction button is clicked', async () => {
        await wrapper.find('#pool_xp_tube_export_button').trigger('click')
        await flushPromises()
        expect(window.open).toHaveBeenCalledWith(wrapper.vm.tractionTubeOpenUrl, '_blank')
      })
    })

    describe('when traction api to check tube fails on mount and component is in failure_tube_check state', () => {
      let wrapper
      beforeEach(async () => {
        mockTubeCheckFailureResponse()
        wrapper = createWrapper()
        // Mock the sleep function to resolve immediately
        wrapper.vm.sleep = vi.fn().mockImplementation(() => Promise.resolve())
        await flushPromises()
      })
      it('displays the correct state', () => {
        expect(wrapper.vm.state).toBe('failure_tube_check')
        verifyComponentState(wrapper, 'failure_tube_check')
      })
      it('remains in failure_tube_check state if response is again failure when refresh button is clicked', async () => {
        await wrapper.find('#pool_xp_tube_export_button').trigger('click')
        await flushPromises()
        expect(wrapper.vm.state).toBe('failure_tube_check')
        verifyComponentState(wrapper, 'failure_tube_check')
      })

      it('transitions to ready_to_export state when no existing tubes are found and the refresh button is clicked', async () => {
        mockNoTubeFoundResponse()
        await wrapper.find('#pool_xp_tube_export_button').trigger('click')
        await flushPromises()
        expect(wrapper.vm.state).toBe('ready_to_export')
        verifyComponentState(wrapper, 'ready_to_export')
      })
      it('transitions to tube_exists state when an existing tube is found when refresh button is clicked', async () => {
        mockTubeFoundResponse()
        await wrapper.find('#pool_xp_tube_export_button').trigger('click')
        await flushPromises()
        expect(wrapper.vm.state).toBe('tube_exists')
        verifyComponentState(wrapper, 'tube_exists')
      })
    })

    describe('when export api fails and the component is in failure_export_tube state', () => {
      let wrapper, originalSleep
      beforeEach(async () => {
        mockNoTubeFoundResponse()
        wrapper = createWrapper()
        originalSleep = wrapper.vm.sleep
        // Mock the sleep function to resolve immediately
        wrapper.vm.sleep = vi.fn().mockImplementation(() => Promise.resolve())
        await flushPromises()
        mockTubeCheckFailureResponse()
        await wrapper.find('#pool_xp_tube_export_button').trigger('click')
        await flushPromises()
      })
      it('displays the correct state', () => {
        expect(wrapper.vm.state).toBe('failure_export_tube')
        verifyComponentState(wrapper, 'failure_export_tube')
      })
      it('immediately transitions to exporting state when export button is clicked', async () => {
        wrapper.vm.sleep = originalSleep
        mockNoTubeFoundResponse()
        await wrapper.find('#pool_xp_tube_export_button').trigger('click')
        await flushPromises()
        expect(wrapper.vm.state).toBe('exporting')
        verifyComponentState(wrapper, 'exporting')
      })
      it('remains in failure_export_tube state if response is failure when retry button is clicked', async () => {
        await wrapper.find('#pool_xp_tube_export_button').trigger('click')
        await flushPromises()
        expect(wrapper.vm.state).toBe('failure_export_tube')
        verifyComponentState(wrapper, 'failure_export_tube')
      })
      it('transitions to tube_export_success state if response is success when retry button is clicked', async () => {
        mockTubeFoundResponse()
        await wrapper.find('#pool_xp_tube_export_button').trigger('click')
        await flushPromises()
        expect(wrapper.vm.state).toBe('tube_export_success')
        verifyComponentState(wrapper, 'tube_export_success')
      })
      it('transitions to failure_tube_check state if response is tube check api fails when retry button is clicked', async () => {
        mockFetch([
          emptyResponse, // Initial successful response
          failedResponse, // Subsequent failure response
        ])
        await wrapper.find('#pool_xp_tube_export_button').trigger('click')
        await flushPromises()
        expect(wrapper.vm.state).toBe('failure_tube_check_export')
        verifyComponentState(wrapper, 'failure_tube_check_export')
      })
    })

    describe('when the traction api to check tube fails after export and the component is in failure_tube_check_export state', () => {
      let wrapper, originalSleep
      beforeEach(async () => {
        mockNoTubeFoundResponse()
        wrapper = createWrapper()
        originalSleep = wrapper.vm.sleep
        // Mock the sleep function to resolve immediately
        wrapper.vm.sleep = vi.fn().mockImplementation(() => Promise.resolve())
        await flushPromises()
        mockTubeCheckFailureResponse()
        await wrapper.find('#pool_xp_tube_export_button').trigger('click')
        await flushPromises()
        mockFetch([
          emptyResponse, // Initial successful response
          failedResponse, // Subsequent failure response
        ])
        await wrapper.find('#pool_xp_tube_export_button').trigger('click')
        await flushPromises()
      })
      it('displays the correct state', () => {
        expect(wrapper.vm.state).toBe('failure_tube_check_export')
        verifyComponentState(wrapper, 'failure_tube_check_export')
      })
      it('immediately transitions to exporting state when retry button is clicked', async () => {
        wrapper.vm.sleep = originalSleep
        mockNoTubeFoundResponse()
        await wrapper.find('#pool_xp_tube_export_button').trigger('click')
        await flushPromises()
        expect(wrapper.vm.state).toBe('exporting')
        verifyComponentState(wrapper, 'exporting')
      })
      it('transitions to tube_export_success state if response is success when retry button is clicked', async () => {
        mockTubeFoundResponse()
        await wrapper.find('#pool_xp_tube_export_button').trigger('click')
        await flushPromises()
        expect(wrapper.vm.state).toBe('tube_export_success')
        verifyComponentState(wrapper, 'tube_export_success')
      })
      it('remains in failure_tube_check_export state if response is failure when retry button is clicked', async () => {
        mockFetch([
          emptyResponse, // Initial successful response
          failedResponse, // Subsequent failure response
        ])
        await wrapper.find('#pool_xp_tube_export_button').trigger('click')
        await flushPromises()
        expect(wrapper.vm.state).toBe('failure_tube_check_export')
        verifyComponentState(wrapper, 'failure_tube_check_export')
      })
    })
  })
})
