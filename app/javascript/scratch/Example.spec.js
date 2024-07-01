import { shallowMount } from '@vue/test-utils'
import Example from './Example.vue'

describe('Example.vue', () => {
  it('renders the component', () => {
    const wrapper = shallowMount(Example)
    expect(wrapper.exists()).toBe(true)
  })

  it('checks the message data property', () => {
    const wrapper = shallowMount(Example)
    expect(wrapper.vm.message).toBe('Hello, World!')
  })

  it('checks the hello computed property', () => {
    const wrapper = shallowMount(Example)
    expect(wrapper.vm.hello).toBe('Hello')
  })

  // Intentionally commented out to show a missing test
  //   it('checks the world method', () => {
  //     const wrapper = shallowMount(Example)
  //     expect(wrapper.vm.world()).toBe('World!')
  //   })
})
