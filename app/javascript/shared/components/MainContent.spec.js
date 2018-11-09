// Import the component being tested
import { shallowMount } from '@vue/test-utils'

import MainContent from 'shared/components/MainContent.vue'
// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
describe('MainContent', () => {
  const wrapper = shallowMount(MainContent, { slots: { default: 'content' } })

  // Inspect the raw component options
  it('renders content-main', () => {
    expect(wrapper.find('.content-main').exists()).toBe(true)
  })

  it('includes the content', () => {
    expect(wrapper.find('.content-main').text()).toBe('content')
  })
})
