// Import the component being tested
import { mount } from '@vue/test-utils'
import CustomTaggedPlateManipulation from './CustomTaggedPlateManipulation.vue'
import mockApi from 'test_support/mock_api'
import localVue from 'test_support/base_vue.js'
import flushPromises from 'flush-promises'

// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
describe('CustomTaggedPlateManipulation', () => {
  const wrapperFactory = function(api = mockApi()) {
    return mount(CustomTaggedPlateManipulation, {
      propsData: {
        devourApi: api.devour,
        tag1GroupOptions: [
            { value: null, text: 'Please select an i7 Tag 1 group...' },
            { value: 1, text: 'i7 example tag group 1' },
            { value: 2, text: 'i7 example tag group 2' }
        ],
        tag2GroupOptions: [
            { value: null, text: 'Please select an i5 Tag 2 group...' },
            { value: 1, text: 'i5 example tag group 1' },
            { value: 2, text: 'i5 example tag group 2' }
        ],
        walkingByOptions: [
            { value: null, text: 'Please select a by Pool/Plate Option...' },
            { value: 'by_pool', text: 'By Pool' },
            { value: 'by_plate_seq', text: 'By Plate (Sequential)' },
            { value: 'by_plate_fixed', text: 'By Plate (Fixed)' }
        ],
        directionOptions: [
            { value: null, text: 'Select a by Row/Column Option...' },
            { value: 'by_rows', text: 'By Rows' },
            { value: 'by_columns', text: 'By Columns' }
        ],
        offsetTagsByOptions: [
            { value: null, text: 'Select which tag index to start at...' },
            { value: 1, text: '1' },
            { value: 2, text: '2' },
            { value: 3, text: '3' },
            { value: 4, text: '4' }
        ]
      },
      localVue
    })
  }

  const nullQcable = { data: [] }
  const emptyQcableData = { plate: null, state: "empty" }
  const goodQcableData = {
    plate: {
      id:"1",
      state:"available",
      lot:{
        id:"1",
        tag_layout_template:{
          id:"1",
          direction:"row",
          walking_by:"wells of plate",
          tag_group:{
            id:"1",
            name:"i7 example tag group 1",
          },
          tag2_group:{
            id:"2",
            name:"i5 example tag group 2",
          }
        }
      }
    },
    state: 'valid'
  }
  const api = mockApi()
    api.mockGet('qcables', {
      filter: { barcode: 'somebarcode' },
      include: { lots: ['templates', { templates: 'tag_group,tag2_group' }] },
      fields: { qcables: 'uuid,state,lot',
                lots: 'uuid,template',
                tag_layout_templates: 'uuid,tag_group,tag2_group,direction_algorithm,walking_algorithm',
                tag_group: 'uuid,name' }
    }, nullQcable)

  it('renders a tag plate scan component', () => {
    let wrapper = wrapperFactory(api)

    expect(wrapper.find('#tag_plate_scan').exists()).toBe(true)
  })

  it('renders a tag1 group select dropdown', () => {
    let wrapper = wrapperFactory(api)

    expect(wrapper.find('#tag1_group_selection').exists()).toBe(true)
    expect(wrapper.find('#tag1_group_selection').element.disabled).toBe(false)
    expect(wrapper.find('#tag1_group_selection').element.value).toEqual('')
  })

  it('renders a tag2 group select dropdown', () => {
    let wrapper = wrapperFactory(api)

    expect(wrapper.find('#tag2_group_selection').exists()).toBe(true)
    expect(wrapper.find('#tag2_group_selection').element.disabled).toBe(false)
    expect(wrapper.find('#tag2_group_selection').element.value).toEqual('')
  })

  it('renders a by pool or plate select dropdown', () => {
    let wrapper = wrapperFactory(api)

    expect(wrapper.find('#by_pool_plate_options').exists()).toBe(true)
  })

  it('renders a by rows or columns select dropdown', () => {
    let wrapper = wrapperFactory(api)

    expect(wrapper.find('#by_rows_columns').exists()).toBe(true)
  })

  it('renders an offset tags by select number dropdown', () => {
    let wrapper = wrapperFactory(api)

    expect(wrapper.find('#offset_tags_by_options').exists()).toBe(true)
  })

  // it('renders a tags per well number based on the plate purpose', () => {
  // })

  it('sets selected on and disables the tag group selects when a tag plate is scanned', async () => {
    let wrapper = wrapperFactory(api)

    wrapper.vm.tagPlateScanned(goodQcableData)

    expect(wrapper.vm.tagPlate).toEqual(goodQcableData.plate)

    expect(wrapper.find('#tag1_group_selection').element.disabled).toBe(true)
    expect(wrapper.find('#tag2_group_selection').element.disabled).toBe(true)

    expect(wrapper.find('#tag1_group_selection').element.value).toEqual('1')
    expect(wrapper.find('#tag2_group_selection').element.value).toEqual('2')
  })

  it('updates tag1GroupId when a tag 1 group is selected', () => {
    let wrapper = wrapperFactory(api)

    expect(wrapper.vm.tag1GroupId).toBe(null)

    wrapper.find('#tag1_group_selection').element.value = 1
    wrapper.find('#tag1_group_selection').trigger('change')

    expect(wrapper.vm.tag1GroupId).toBe(1)
  })

  it('updates tag2GroupId when a tag 2 group is selected', () => {
    let wrapper = wrapperFactory(api)

    expect(wrapper.vm.tag2GroupId).toBe(null)

    wrapper.find('#tag2_group_selection').element.value = 1
    wrapper.find('#tag2_group_selection').trigger('change')

    expect(wrapper.vm.tag2GroupId).toBe(1)
  })

  it('re-enables the tag group selects when the tag plate is cleared', () => {
    let wrapper = wrapperFactory(api)

    wrapper.vm.tagPlateScanned(goodQcableData)

    expect(wrapper.find('#tag1_group_selection').element.disabled).toBe(true)
    expect(wrapper.find('#tag2_group_selection').element.disabled).toBe(true)

    expect(wrapper.find('#tag1_group_selection').element.value).toEqual('1')
    expect(wrapper.find('#tag2_group_selection').element.value).toEqual('2')

    wrapper.vm.tagPlateScanned(emptyQcableData)

    expect(wrapper.find('#tag1_group_selection').element.disabled).toBe(false)
    expect(wrapper.find('#tag2_group_selection').element.disabled).toBe(false)

    expect(wrapper.find('#tag1_group_selection').element.value).toEqual('')
    expect(wrapper.find('#tag2_group_selection').element.value).toEqual('')

    expect(wrapper.vm.tag1GroupId).toEqual(null)
    expect(wrapper.vm.tag2GroupId).toEqual(null)
    expect(wrapper.vm.tagPlate).toEqual(null)
  })

  it('disables the tag plate scan input if a tag group 1 or 2 is selected', () => {
    let wrapper = wrapperFactory(api)

    expect(wrapper.vm.tagPlateScanDisabled).toBe(false)

    wrapper.find('#tag1_group_selection').element.value = 1
    wrapper.find('#tag1_group_selection').trigger('change')

    expect(wrapper.vm.tagPlateScanDisabled).toBe(true)

    expect(wrapper.find('#plateScan').element.disabled).toBe(true)
  })

  it('emits a call to the parent container on a change of the form data', () => {
    let wrapper = wrapperFactory(api)
    const emitted = wrapper.emitted()

    expect(wrapper.find('#by_pool_plate_options').exists()).toBe(true)

    const input = wrapper.find('#by_pool_plate_options')
    const option = input.find(`option[value="by_plate_fixed"]`)
    option.setSelected()
    input.trigger('input')

    expect(wrapper.emitted().tagparamsupdated.length).toBe(1)
    expect(wrapper.emitted().tagparamsupdated[0]).toEqual(
      [{"tag1GroupId":null,"tag2GroupId":null,"walkingBy":"by_plate_fixed","direction":"by_rows","offsetTagsByOption":null}]
    )
  })

  it('returns empty offset tags by options and disables the select when number of target wells is zero', () => {
    const wrapper = wrapperFactory()

    wrapper.setProps({ numberOfTags: 5, numberOfTargetWells: 0 })

    const badOffsetOptions = [
      { value: null, text: 'No target wells found..' }
    ]

    expect(wrapper.vm.offsetTagsByOptions).toEqual(badOffsetOptions)
    expect(wrapper.vm.offsetDisabled).toBe(true)
  })

  it('returns empty offset tags by options and disables the select when number of tags is zero', () => {
    const wrapper = wrapperFactory()

    wrapper.setProps({ numberOfTags: 0 })

    const badOffsetOptions = [
      { value: null, text: 'Select tags first..' }
    ]

    expect(wrapper.vm.offsetTagsByOptions).toEqual(badOffsetOptions)
    expect(wrapper.vm.offsetDisabled).toBe(true)
  })

  it('returns empty offset tags by options and disables the select for an invalid combination', () => {
    const wrapper = wrapperFactory()

    wrapper.setProps({ numberOfTags: 2, numberOfTargetWells: 3 })

    const badOffsetOptions = [
      { value: null, text: 'Not enough tags to enable offset..' }
    ]

    expect(wrapper.vm.offsetTagsByOptions).toEqual(badOffsetOptions)
    expect(wrapper.vm.offsetDisabled).toBe(true)
  })

  it('returns the correct computed offset tags by options when more tags than target wells', () => {
    const wrapper = wrapperFactory()

    wrapper.setProps({ numberOfTags: 4, numberOfTargetWells: 2 })

    const goodOffsetOptions = [
      { value: 0, text: '1' },
      { value: 1, text: '2' },
      { value: 2, text: '3' }
    ]

    expect(wrapper.vm.offsetTagsByOptions).toEqual(goodOffsetOptions)
    expect(wrapper.vm.offsetDisabled).toBe(false)
  })

  it('returns the correct computed offset tags by options when same number of tags as target wells', () => {
    const wrapper = wrapperFactory()

    wrapper.setProps({ numberOfTags: 3, numberOfTargetWells: 3 })

    const goodOffsetOptions = [
      { value: 0, text: '1' }
    ]

    expect(wrapper.vm.offsetTagsByOptions).toEqual(goodOffsetOptions)
    expect(wrapper.vm.offsetDisabled).toBe(false)
  })
})
