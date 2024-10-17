import { mount, createLocalVue } from '@vue/test-utils'
import flushPromises from 'flush-promises'
import PoolXPTubeSubmitPanel from './PoolXPTubeSubmitPanel.vue'
import BootstrapVue from 'bootstrap-vue'
import { beforeEach, expect, it, vi } from 'vitest'
import ReadyIcon from '../../icons/ReadyIcon.vue'
import TubeSearchIcon from '../../icons/TubeSearchIcon.vue'
import SuccessIcon from '../../icons/SuccessIcon.vue'
import ErrorIcon from '../../icons/ErrorIcon.vue'
import TubeIcon from '../../icons/TubeIcon.vue'

const localVue = createLocalVue()
localVue.use(BootstrapVue)

describe('PoolXPTubeSubmitPanel', () => {
  let wrapper

  const maxPollAttempts = 10
  const pollInterval = 1000

  const defaultProps = {
    barcode: '12345',
    userId: 'user123',
    sequencescapeApiUrl: 'http://example.com/api',
    tractionServiceUrl: 'http://traction.example.com',
    tractionUIUrl: 'http://traction-ui.example.com',
  }

  const createWrapper = (state = 'initial', props = { ...defaultProps }) => {
    return mount(PoolXPTubeSubmitPanel, {
      localVue,
      propsData: {
        ...props,
      },
      data() {
        return {
          state,
        }
      },
    })
  }

  const spyMethod = (method) => vi.spyOn(PoolXPTubeSubmitPanel.methods, method)

  beforeEach(() => {
    vi.useFakeTimers()
  })
  afterEach(() => {
    vi.useRealTimers()
  })

  const verifyComponentState = (wrapper, state) => {
    const exportButton = wrapper.find('#pool_xp_tube_export_button')
    const statusLabel = wrapper.find('#pool_xp_tube_export_status')
    const spinner = wrapper.find('#progress_spinner')
    const statusIcon = wrapper.find('#status_icon')
    switch (state) {
      case 'initial': {
        expect(exportButton.exists()).toBe(true)
        expect(statusLabel.exists()).toBe(true)
        expect(spinner.isVisible()).toBe(false)
        expect(statusIcon.isVisible()).toBe(true)
        expect(exportButton.attributes('disabled')).toBeUndefined()
        expect(exportButton.classes()).toContain('btn-success')
        expect(statusLabel.classes()).toContain('text-success')
        expect(statusLabel.text()).toBe('Ready to export')
        expect(exportButton.text()).toBe('Export')
        const iconComponent = statusIcon.findComponent(ReadyIcon)
        expect(iconComponent.exists()).toBe(true)
        expect(iconComponent.props().color).toBe('green')
        break
      }

      case 'fetching': {
        expect(exportButton.exists()).toBe(true)
        expect(statusLabel.exists()).toBe(true)
        expect(spinner.isVisible()).toBe(true)
        expect(statusIcon.isVisible()).toBe(true)
        expect(exportButton.attributes('disabled')).toBe('disabled')
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
        expect(exportButton.attributes('disabled')).toBeUndefined()
        expect(exportButton.classes()).toContain('btn-success')
        expect(statusLabel.classes()).toContain('text-success')
        expect(statusLabel.text()).toBe('Tube already exported to Traction')
        expect(exportButton.text()).toBe('Open Traction')
        const iconComponent = statusIcon.findComponent(SuccessIcon)
        expect(iconComponent.exists()).toBe(true)
        expect(iconComponent.props().color).toContain('green')
        break
      }

      case 'polling': {
        expect(exportButton.exists()).toBe(true)
        expect(statusLabel.exists()).toBe(true)
        expect(spinner.isVisible()).toBe(true)
        expect(statusIcon.isVisible()).toBe(true)
        expect(exportButton.attributes('disabled')).toBe('disabled')
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
        expect(exportButton.attributes('disabled')).toBeUndefined()
        expect(exportButton.classes()).toContain('btn-success')
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
        expect(exportButton.attributes('disabled')).toBeUndefined()
        expect(exportButton.classes()).toContain('btn-warning')
        expect(statusLabel.classes()).toContain('text-warning')
        expect(statusLabel.text()).toBe('Unable to send tube to Traction. Try again?')
        expect(exportButton.text()).toBe('Retry')
        const iconComponent = statusIcon.findComponent(ErrorIcon)
        expect(iconComponent.exists()).toBe(true)
        expect(iconComponent.props().color).toContain('orange')
        break
      }

      case 'failure_poll_tube': {
        expect(exportButton.exists()).toBe(true)
        expect(statusLabel.exists()).toBe(true)
        expect(spinner.isVisible()).toBe(false)
        expect(statusIcon.isVisible()).toBe(true)
        expect(exportButton.attributes('disabled')).toBeUndefined()
        expect(exportButton.classes()).toContain('btn-warning')
        expect(statusLabel.classes()).toContain('text-warning')
        expect(statusLabel.text()).toBe('Unable to check whether tube is in Traction. Try again?')
        expect(exportButton.text()).toBe('Refresh')
        const iconComponent = statusIcon.findComponent(ErrorIcon)
        expect(iconComponent.exists()).toBe(true)
        expect(iconComponent.props().color).toContain('orange')
        break
      }

      case 'failure_export_tube_after_recheck': {
        expect(exportButton.exists()).toBe(true)
        expect(statusLabel.exists()).toBe(true)
        expect(spinner.isVisible()).toBe(false)
        expect(statusIcon.isVisible()).toBe(true)
        expect(exportButton.attributes('disabled')).toBeUndefined()
        expect(exportButton.classes()).toContain('btn-primary')
        expect(statusLabel.classes()).toContain('text-danger')
        expect(statusLabel.text()).toBe('Unable to send tube to Traction')
        expect(exportButton.text()).toBe('Export')
        const iconComponent = statusIcon.findComponent(ErrorIcon)
        expect(iconComponent.exists()).toBe(true)
        expect(iconComponent.props().color).toContain('red')
        break
      }

      case 'invalid_props': {
        expect(exportButton.exists()).toBe(true)
        expect(statusLabel.exists()).toBe(true)
        expect(spinner.isVisible()).toBe(false)
        expect(statusIcon.isVisible()).toBe(true)
        expect(exportButton.attributes('disabled')).toBe('disabled')
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

  it('renders the component', () => {
    wrapper = createWrapper()
    expect(wrapper.exists()).toBe(true)
  })

  it.each([
    'initial',
    'fetching',
    'tube_exists',
    'polling',
    'tube_export_success',
    'failure_export_tube',
    'failure_poll_tube',
    'failure_export_tube_after_recheck',
    'invalid_props',
  ])('displays the correct status based on %s state', (stateValue) => {
    const wrapper = createWrapper(stateValue)
    verifyComponentState(wrapper, stateValue)
  })

  describe('on Mount', () => {
    it('calls isTubeInTraction on mount', async () => {
      vi.spyOn(PoolXPTubeSubmitPanel.methods, 'isTubeInTraction')
      wrapper = createWrapper()
      expect(PoolXPTubeSubmitPanel.methods.isTubeInTraction).toHaveBeenCalled()
    })

    it('handles invalid props correctly on mount', async () => {
      wrapper = createWrapper('initial', {
        barcode: '',
        userId: '',
        sequencescapeApiUrl: '',
        tractionServiceUrl: '',
        tractionUIUrl: 'http://traction-ui.example.com',
      })
      await flushPromises()
      expect(wrapper.vm.state).toBe('invalid_props')
      verifyComponentState(wrapper, 'invalid_props')
    })

    it('handles fetching tube success from Traction correctly on mount', async () => {
      vi.spyOn(global, 'fetch').mockImplementation(() =>
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ data: [{ id: '1' }] }),
        }),
      )

      wrapper = createWrapper()
      await flushPromises()
      expect(global.fetch).toBeCalledTimes(1)
      expect(global.fetch).toHaveBeenCalledWith(wrapper.vm.tractionTubeCheckUrl)

      expect(wrapper.vm.state).toBe('tube_exists')
      verifyComponentState(wrapper, 'tube_exists')
    })

    it('handles fetching tube failure from Traction correctly on mount', async () => {
      vi.spyOn(global, 'fetch').mockImplementation(() =>
        Promise.resolve({
          ok: false,
          json: () => Promise.resolve({ error: 'API call failed' }),
        }),
      )
      wrapper = createWrapper()
      await flushPromises()
      expect(wrapper.vm.state).toBe('initial')
      verifyComponentState(wrapper, 'initial')
    })
  })

  describe('Export action', () => {
    it('handleSubmit on button click', async () => {
      const spyHandleSubmit = spyMethod('handleSubmit')
      wrapper = createWrapper()
      await wrapper.find('#pool_xp_tube_export_button').trigger('click')
      expect(spyHandleSubmit).toHaveBeenCalled()
    })
    it('calls exportTubeToTraction when handleSubmit is invoked in the normal state', async () => {
      const spyExportTubeToTraction = spyMethod('exportTubeToTraction')
      wrapper = createWrapper()
      await wrapper.find('#pool_xp_tube_export_button').trigger('click')
      expect(spyExportTubeToTraction).toHaveBeenCalled()
    })
    it('calls isTubeInTraction when handleSubmit is invoked in the failure_poll_tube state', async () => {
      const spyExportTubeToTraction = spyMethod('exportTubeToTraction')
      const spyIsTubeInTraction = spyMethod('isTubeInTraction')
      wrapper = createWrapper()
      wrapper.setData({ state: 'failure_poll_tube' })
      await wrapper.find('#pool_xp_tube_export_button').trigger('click')
      expect(spyIsTubeInTraction).toHaveBeenCalled()
      expect(spyExportTubeToTraction).not.toHaveBeenCalled()
    })

    it.each(['tube_export_success', 'tube_exists'])(
      'opens Traction in a new tab when handleSubmit is invoked in the %s state',
      async (stateValue) => {
        const spyWindowOpen = vi.spyOn(window, 'open').mockImplementation(() => {})
        const wrapper = createWrapper()

        // Set the state and trigger the click
        wrapper.setData({ state: stateValue })
        await wrapper.find('#pool_xp_tube_export_button').trigger('click')
        expect(spyWindowOpen).toHaveBeenCalledWith(wrapper.vm.tractionTubeOpenUrl, '_blank')
      },
    )
    it('handles export tube success correctly', async () => {
      vi.spyOn(global, 'fetch').mockImplementation(() =>
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ data: [] }),
        }),
      )

      const spyPollTractionForTube = spyMethod('pollTractionForTube')
      wrapper = createWrapper()
      await flushPromises()
      await wrapper.find('#pool_xp_tube_export_button').trigger('click')
      await flushPromises()
      expect(global.fetch).toHaveBeenCalledWith(wrapper.vm.sequencescapeApiExportUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(wrapper.vm.submitPayload),
      })
      expect(spyPollTractionForTube).toHaveBeenCalled()
      expect(wrapper.vm.state).toBe('polling')
      verifyComponentState(wrapper, 'polling')
    })
    it('handles export tube failure correctly', async () => {
      vi.spyOn(global, 'fetch').mockImplementation(() =>
        Promise.resolve({
          ok: false,
          json: () => Promise.resolve({ error: 'API call failed' }),
        }),
      )
      const spyPollTractionForTube = spyMethod('pollTractionForTube')
      wrapper = createWrapper()
      await flushPromises()
      await wrapper.find('#pool_xp_tube_export_button').trigger('click')
      await flushPromises()
      expect(wrapper.vm.state).toBe('failure_export_tube')
      expect(spyPollTractionForTube).not.toHaveBeenCalled()
      verifyComponentState(wrapper, 'failure_export_tube')
    })

    it('handles export tube and pollTractionForTube successes correctly', async () => {
      vi.spyOn(global, 'fetch').mockImplementationOnce(() =>
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ data: [{ id: '1' }] }),
        }),
      )
      wrapper = createWrapper()
      await flushPromises()
      await wrapper.find('#pool_xp_tube_export_button').trigger('click')
      vi.advanceTimersByTime(pollInterval)
      await flushPromises()
      expect(wrapper.vm.state).toBe('tube_exists')
      verifyComponentState(wrapper, 'tube_exists')
    })

    it('handles export tube success and pollTractionForTube failure correctly', async () => {
      vi.spyOn(global, 'fetch')
        .mockImplementationOnce(() =>
          Promise.resolve({
            ok: true,
            json: () => Promise.resolve({ data: [] }),
          }),
        )
        .mockImplementationOnce(() =>
          Promise.resolve({
            ok: true,
            json: () => Promise.resolve({ data: [] }),
          }),
        )
        .mockImplementation(() =>
          Promise.resolve({
            ok: false,
            json: () => Promise.resolve({ error: 'API call failed' }),
          }),
        )
      wrapper = createWrapper()
      await flushPromises()
      await wrapper.find('#pool_xp_tube_export_button').trigger('click')
      await flushPromises()
      // Fast-forward time to simulate the polling intervals
      for (let i = 0; i <= maxPollAttempts; i++) {
        vi.advanceTimersByTime(pollInterval)
        await flushPromises()
      }
      await flushPromises()
      expect(wrapper.vm.state).toBe('failure_poll_tube')
      verifyComponentState(wrapper, 'failure_poll_tube')
    })
  })
  it('handles export tube success and pollTractionForTube success correctly', async () => {
    vi.spyOn(global, 'fetch')
      .mockImplementationOnce(() =>
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ data: [] }),
        }),
      )
      .mockImplementationOnce(() =>
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ data: [] }),
        }),
      )
      .mockImplementation(() =>
        Promise.resolve({
          ok: true,
          json: () => Promise.resolve({ data: [{ id: '1' }] }),
        }),
      )
    wrapper = createWrapper()
    await flushPromises()
    await wrapper.find('#pool_xp_tube_export_button').trigger('click')
    await flushPromises()
    // Fast-forward time to simulate the polling intervals
    for (let i = 0; i <= maxPollAttempts; i++) {
      vi.advanceTimersByTime(pollInterval)
      await flushPromises()
    }
    await flushPromises()
    expect(wrapper.vm.state).toBe('tube_export_success')
    verifyComponentState(wrapper, 'tube_export_success')
  })
})
