// Import the component being tested
import { shallowMount } from '@vue/test-utils'

import PlateScan from 'shared/components/PlateScan.vue'
// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
describe('PlateScan', () => {
  const myCaption = 'Caption'
  const wrapper = shallowMount(PlateScan, { propsData: { columns: 12, rows: 8, caption: myCaption } })

  // Inspect the raw component options
  it('renders a plate', () => {
    expect(wrapper.find('table.plate-view').exists()).toBe(true)
  })

  it('sets an appropriate size', () => {
    expect(wrapper.find('table.plate-96').exists()).toBe(true)
  })

  it('renders a provided caption', () =>{
    expect(wrapper.find('table.plate-view caption').text()).toBe(myCaption)
  })

  it('uses the provided dimensions', () => {
    expect(wrapper.find('table.plate-view').findAll('div.well').length).toBe(96)
  })

  it('Renders rows as letters', () => {
    expect(wrapper.find('tbody').findAll('th').at(0).text()).toBe('A')
    expect(wrapper.find('tbody').findAll('th').at(1).text()).toBe('B')
    expect(wrapper.find('tbody').findAll('th').at(2).text()).toBe('C')
  })
})
