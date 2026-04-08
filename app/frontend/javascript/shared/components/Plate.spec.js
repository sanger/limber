// Import the component being tested
import { shallowMount } from '@vue/test-utils'
import { plateFactory } from '@/javascript/test_support/factories.js'

import LbPlate from '@/javascript/shared/components/Plate.vue'
// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
describe('LbPlate', () => {
  const myCaption = 'Caption'
  const wells = {}
  // Populate the wells props with a full plate worth of wells
  plateFactory({ _wellOptions: { colour_index: 1 } }).wells.forEach((well) => (wells[well.position.name] = well))
  const wrapper = shallowMount(LbPlate, {
    props: { columns: 12, rows: 8, caption: myCaption, wells: wells },
  })

  // Inspect the raw component options
  it('renders a plate', () => {
    expect(wrapper.find('table.plate-view').exists()).toBe(true)
  })

  it('sets an appropriate size', () => {
    expect(wrapper.find('table.plate-96').exists()).toBe(true)
  })

  it('renders a provided caption', () => {
    expect(wrapper.find('table.plate-view caption').text()).toBe(myCaption)
  })

  it('uses the provided dimensions', () => {
    expect(wrapper.find('table.plate-view').findAll('lb-well-stub').length).toBe(96)
  })

  it('Renders rows as letters', () => {
    expect(wrapper.find('tbody').findAll('th').at(0).text()).toBe('A')
    expect(wrapper.find('tbody').findAll('th').at(1).text()).toBe('B')
    expect(wrapper.find('tbody').findAll('th').at(2).text()).toBe('C')
  })

  it('emits a well clicked event', () => {
    wrapper.vm.onWellClicked('A1')
    const emitted = wrapper.emitted()

    expect(emitted.onwellclicked.length).toBe(1)
    expect(emitted.onwellclicked[0]).toEqual(['A1'])
  })
})
