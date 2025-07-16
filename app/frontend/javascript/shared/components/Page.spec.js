// Import the component being tested
import { shallowMount } from '@vue/test-utils'
import Page from '@/javascript/shared/components/Page.vue'
import Alert from '@/javascript/shared/components/Alert.vue'
import eventBus from '@/javascript/shared/eventBus.js'

describe('Page', () => {
  const wrapperFactory = () => {
    return shallowMount(Page, { slots: { default: 'content' } })
  }

  // Inspect the raw component options
  it('renders container-fluid', () => {
    const wrapper = wrapperFactory()
    expect(wrapper.find('.container-fluid').exists()).toBe(true)
  })

  it('wraps everything in a row', () => {
    const wrapper = wrapperFactory()
    expect(wrapper.find('.container-fluid').find('.row').exists()).toBe(true)
  })

  it('includes the content', () => {
    const wrapper = wrapperFactory()
    expect(wrapper.find('.row').text()).toBe('content')
  })

  describe('Alert handling', () => {
    it('renders an alert when an alert is emitted', async () => {
      const wrapper = wrapperFactory()
      eventBus.$emit('push-alert', { level: 'danger', title: 'title', message: 'message' })
      await wrapper.vm.$nextTick()

      const alert = wrapper.find('.js-alerts').findComponent(Alert)
      expect(alert.exists()).toBe(true)
      expect(alert.props().level).toBe('danger')
      expect(alert.props().title).toBe('title')
      expect(alert.props().message).toBe('message')
    })

    it('renders multiple alerts when multiple alerts are emitted', async () => {
      const wrapper = wrapperFactory()
      eventBus.$emit('push-alert', { level: 'info', title: 'title', message: 'info-message' })
      eventBus.$emit('push-alert', { level: 'warning', title: 'title', message: 'warning-message' })
      eventBus.$emit('push-alert', { level: 'danger', title: 'title', message: 'danger-message' })
      await wrapper.vm.$nextTick()

      const alerts = wrapper.findAllComponents(Alert)
      expect(alerts).toHaveLength(3)
      expect(alerts.at(0).props().level).toBe('info')
      expect(alerts.at(1).props().level).toBe('warning')
      expect(alerts.at(2).props().level).toBe('danger')
    })

    it('closes an alert when the close button is clicked', async () => {
      const wrapper = wrapperFactory()
      eventBus.$emit('push-alert', { level: 'info', title: 'title', message: 'info-message' })
      eventBus.$emit('push-alert', { level: 'warning', title: 'title', message: 'warning-message' })
      eventBus.$emit('push-alert', { level: 'danger', title: 'title', message: 'danger-message' })
      await wrapper.vm.$nextTick()

      const alertsBefore = wrapper.findAllComponents(Alert)
      expect(alertsBefore).toHaveLength(3) // checks alerts added to DOM

      const alertToClose = alertsBefore.at(1) // select middle alert
      alertToClose.vm.$emit('close') // alert send close event to parent
      await wrapper.vm.$nextTick()

      const alertsAfter = wrapper.findAllComponents(Alert)
      expect(alertsAfter).toHaveLength(2) // checks alert removed from DOM
      // check that uid of alert that was closed is not in the list of alerts
      expect(alertsAfter.map((alert) => alert.vm.message)).not.toContain(alertToClose.vm.message)
    })
  })
})
