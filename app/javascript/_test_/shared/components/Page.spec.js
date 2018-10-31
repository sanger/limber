// Import the component being tested
import { shallowMount } from '@vue/test-utils'

import Page from 'shared/components/Page.vue'
// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
describe('Page', () => {
  const wrapper = shallowMount(Page, { slots: { default: 'content' } })

  // Inspect the raw component options
  it('renders container-fluid', () => {
    expect(wrapper.find('.container-fluid').exists()).toBe(true)
  })

  it('wraps everything in a row', () => {
    expect(wrapper.find('.container-fluid').find('.row').exists()).toBe(true)
  })

  it('includes the content', () => {
    expect(wrapper.find('.row').text()).toBe('content')
  })
})
