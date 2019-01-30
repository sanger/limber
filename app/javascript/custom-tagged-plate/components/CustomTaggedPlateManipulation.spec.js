// Import the component being tested
import { shallowMount } from '@vue/test-utils'

import CustomTaggedPlateManipulation from './CustomTaggedPlateManipulation.vue'
// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
describe('CustomTaggedPlateManipulation', () => {
  // const myCaption = 'Caption'
  const wrapper = shallowMount(CustomTaggedPlateManipulation, { propsData: {} })

  // Inspect the raw component options
  it('renders a tag plate scan component', () => {
    expect(wrapper.find('#tag_plate_scan').exists()).toBe(true)
  })

  it('renders a tag1 group select dropdown', () => {
    expect(wrapper.find('#tag1_group_selection').exists()).toBe(true)
  })

  it('renders a tag2 group select dropdown', () => {
    expect(wrapper.find('#tag2_group_selection').exists()).toBe(true)
  })

  it('renders a by pool or plate select dropdown', () => {
    expect(wrapper.find('#by_pool_plate_options').exists()).toBe(true)
  })

  it('renders a by rows or columns select dropdown', () => {
    expect(wrapper.find('#by_rows_columns').exists()).toBe(true)
  })

  it('renders a start at tag select number dropdown', () => {
    expect(wrapper.find('#start_at_tag_options').exists()).toBe(true)
  })

  // it('renders a tags per well number based on the plate purpose', () => {
  // })

  // it('renders tag group labels instead of selects when a tag plate is scanned', () => {
  // })

  // it('disables the tag plate scan input if a tag group 1 or 2 is selected', () => {
  // })

  it('emits a call to the parent container on any change of the form data', () => {
    const emitted = wrapper.emitted()

    wrapper.vm.form.byPoolPlateOption = 'by_plate_seq'
    wrapper.vm.updateTagParams('')

    expect(wrapper.emitted().tagparamsupdated.length).toBe(1)
    expect(wrapper.emitted().tagparamsupdated[0]).toEqual(
      [{"tagPlateBarcode":null,
         "tag1Group":null,
         "tag2Group":null,
         "byPoolPlateOption":"by_plate_seq",
         "byRowColOption":"by_rows",
         "startAtTagOption":1,
         "tagsPerWellOption":1}]
    )
  })
})
