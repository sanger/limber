import { shallowMount } from '@vue/test-utils'
import Alert from './Alert.vue'

describe('Alert.vue', () => {
  it('renders props when passed', () => {
    const level = 'warning'
    const title = 'Test Title'
    const message = 'Test Message'
    const wrapper = shallowMount(Alert, {
      propsData: { level, title, message },
    })

    expect(wrapper.classes()).toContain(`alert-${level}`)
    expect(wrapper.text()).toContain(title)
    expect(wrapper.text()).toContain(message)
  })

  it('has default props when none are passed', () => {
    const wrapper = shallowMount(Alert)

    expect(wrapper.classes()).toContain('alert-info')
    expect(wrapper.text()).toContain(':')
  })

  it('closes when close button is clicked', async () => {
    const wrapper = shallowMount(Alert)
    await wrapper.find('button.close').trigger('click')

    expect(wrapper.isVisible()).toBe(false)
  })
})
