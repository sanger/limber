// Import the component being tested
import { shallowMount } from '@vue/test-utils'

import Sidebar from 'shared/components/Sidebar.vue'
// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
describe('Sidebar', () => {
  const wrapper = shallowMount(Sidebar, { slots: { default: 'content' } })

  // Inspect the raw component options
  it('renders content-secondary', () => {
    expect(wrapper.find('.content-secondary.sidebar').exists()).toBe(true)
  })

  it('includes the content', () => {
    expect(wrapper.find('.content-secondary').text()).toBe('content')
  })
})
