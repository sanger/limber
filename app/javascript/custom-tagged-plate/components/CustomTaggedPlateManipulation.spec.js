// Import the component being tested
import { mount } from '@vue/test-utils'
import CustomTaggedPlateManipulation from './CustomTaggedPlateManipulation.vue'
import mockApi from 'test_support/mock_api'
import localVue from 'test_support/base_vue.js'
import MockAdapter from 'axios-mock-adapter'

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
        ]
      },
      localVue
    })
  }

  const nullQcable = { data: [] }
  const emptyQcableData = { plate: null, state: 'empty' }
  const goodQcableData = {
    plate: {
      id:'1',
      state:'available',
      lot:{
        id:'1',
        tag_layout_template:{
          id:'1',
          direction:'row',
          walking_by:'wells of plate',
          tag_group:{
            id:'1',
            name:'i7 example tag group 1',
          },
          tag2_group:{
            id:'2',
            name:'i5 example tag group 2',
          }
        }
      }
    },
    state: 'valid'
  }
  const api = mockApi()
  api.mockGet('qcables', {
    filter: {
      barcode: 'somebarcode'
    },
    include: {
      lots: ['templates', {
        templates: 'tag_group,tag2_group'
      }]
    },
    fields: {
      qcables: 'uuid,state,lot',
      lots: 'uuid,template',
      tag_layout_templates: 'uuid,tag_group,tag2_group,direction_algorithm,walking_algorithm',
      tag_group: 'uuid,name'
    }
  }, nullQcable)

  describe("#computed function tests:", () => {
    describe("tagGroupsDisabled:", () => {
      it('returns false if a tag plate has not been scanned', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setData({ tagPlate: null })

        expect(wrapper.vm.tagGroupsDisabled).toBe(false)
      })

      it('returns true if a valid tag plate was scanned', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setData({ tagPlate: goodQcableData.plate })

        expect(wrapper.vm.tagGroupsDisabled).toBe(true)
      })
    })

    describe("startAtTagMax:", () => {
      it('returns expected value if tags and target wells exist', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 5, numberOfTargetWells: 5 })

        expect(wrapper.vm.startAtTagMax).toBe(1)
        expect(wrapper.vm.startAtTagDisabled).toBe(true)
        expect(wrapper.vm.startAtTagPlaceholder).toBe('No spare tags..')
      })

      it('returns expected value if tags are in excess', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 10, numberOfTargetWells: 5 })

        expect(wrapper.vm.startAtTagMax).toBe(6)
        expect(wrapper.vm.startAtTagDisabled).toBe(false)
        expect(wrapper.vm.startAtTagPlaceholder).toBe('Enter an offset value..')
      })

      it('returns a negative number if there are not enough tags', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 5, numberOfTargetWells: 10 })

        expect(wrapper.vm.startAtTagMax).toBe(-4)
        expect(wrapper.vm.startAtTagDisabled).toBe(true)
        expect(wrapper.vm.startAtTagPlaceholder).toBe('Not enough tags..')
      })

      it('returns null if there are no tags', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 0, numberOfTargetWells: 5 })

        expect(wrapper.vm.startAtTagMax).toEqual(null)
        expect(wrapper.vm.startAtTagDisabled).toBe(true)
        expect(wrapper.vm.startAtTagPlaceholder).toBe('Select tags first..')
      })

      it('returns null if there are no target wells', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 5, numberOfTargetWells: 0 })

        expect(wrapper.vm.startAtTagMax).toEqual(null)
        expect(wrapper.vm.startAtTagDisabled).toBe(true)
        expect(wrapper.vm.startAtTagPlaceholder).toBe('No target wells found..')
      })
    })

    describe("startAtTagState:", () => {
      it('returns null if there is no start at tag number', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setData({ startAtTagNumber: null })

        expect(wrapper.vm.startAtTagState).toEqual(null)
        expect(wrapper.vm.startAtTagValidFeedback).toEqual('')
      })

      it('returns true if the entered number is valid', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        wrapper.setData({ startAtTagMin: 1, startAtTagStep: 1, startAtTagNumber: 5 })

        expect(wrapper.vm.startAtTagMax).toBe(10)
        expect(wrapper.vm.startAtTagState).toBe(true)
        expect(wrapper.vm.startAtTagValidFeedback).toEqual('Valid')
      })

      it('returns false if the entered number is too high', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        wrapper.setData({ startAtTagMin: 1, startAtTagStep: 1, startAtTagNumber: 11 })

        expect(wrapper.vm.startAtTagMax).toBe(10)
        expect(wrapper.vm.startAtTagState).toBe(false)
        expect(wrapper.vm.startAtTagValidFeedback).toEqual('')
      })

      it('returns false if the entered number is too low', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        wrapper.setData({ startAtTagMin: 1, startAtTagStep: 1, startAtTagNumber: 0 })

        expect(wrapper.vm.startAtTagMax).toBe(10)
        expect(wrapper.vm.startAtTagState).toBe(false)
        expect(wrapper.vm.startAtTagValidFeedback).toEqual('')
      })

      it('returns false if the entered number is between steps', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        wrapper.setData({ startAtTagMin: 1, startAtTagStep: 2, startAtTagNumber: 3 })

        expect(wrapper.vm.startAtTagMax).toBe(10)
        expect(wrapper.vm.startAtTagState).toBe(false)
        expect(wrapper.vm.startAtTagValidFeedback).toEqual('')
      })
    })

    describe("startAtTagInvalidFeedback:", () => {
      it('returns empty string if the entered number is null', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setData({ startAtTagNumber: null })

        expect(wrapper.vm.startAtTagInvalidFeedback).toEqual('')
      })

      it('returns empty string if the max is not set', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 0, numberOfTargetWells: 0 })
        wrapper.setData({ startAtTagNumber: 1 })

        expect(wrapper.vm.startAtTagMax).toEqual(null)
        expect(wrapper.vm.startAtTagInvalidFeedback).toEqual('')
      })

      it('returns empty string if the entered number is valid', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        wrapper.setData({ startAtTagMin: 1, startAtTagStep: 1, startAtTagNumber: 5 })

        expect(wrapper.vm.startAtTagMax).toBe(10)
        expect(wrapper.vm.startAtTagInvalidFeedback).toEqual('')
      })

      it('returns correctly if the entered number is too high', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        wrapper.setData({ startAtTagMin: 1, startAtTagStep: 1, startAtTagNumber: 11 })

        expect(wrapper.vm.startAtTagMax).toBe(10)
        expect(wrapper.vm.startAtTagInvalidFeedback).toEqual('Start must be less than or equal to 10')
      })

      it('returns correctly if the entered number is too low', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        wrapper.setData({ startAtTagMin: 1, startAtTagStep: 1, startAtTagNumber: 0 })

        expect(wrapper.vm.startAtTagMax).toBe(10)
        expect(wrapper.vm.startAtTagInvalidFeedback).toEqual('Start must be greater than or equal to 1')
      })

      it('returns correctly if the entered number is between steps', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        wrapper.setData({ startAtTagMin: 1, startAtTagStep: 2, startAtTagNumber: 3 })

        expect(wrapper.vm.startAtTagMax).toBe(10)
        expect(wrapper.vm.startAtTagInvalidFeedback).toEqual('Start must be divisible by 2')
      })
    })
  })

  describe("#rendering tests:", () => {
    it('renders a tag plate scan component', () => {
      const wrapper = wrapperFactory(api)

      expect(wrapper.find('#tag_plate_scan').exists()).toBe(true)
    })

    it('renders a tag1 group select dropdown', () => {
      const wrapper = wrapperFactory(api)

      expect(wrapper.find('#tag1_group_selection').exists()).toBe(true)
      expect(wrapper.find('#tag1_group_selection').element.disabled).toBe(false)
      expect(wrapper.find('#tag1_group_selection').element.value).toEqual('')
    })

    it('renders a tag2 group select dropdown', () => {
      const wrapper = wrapperFactory(api)

      expect(wrapper.find('#tag2_group_selection').exists()).toBe(true)
      expect(wrapper.find('#tag2_group_selection').element.disabled).toBe(false)
      expect(wrapper.find('#tag2_group_selection').element.value).toEqual('')
    })

    it('renders a by pool or plate select dropdown', () => {
      const wrapper = wrapperFactory(api)

      expect(wrapper.find('#by_pool_plate_options').exists()).toBe(true)
    })

    it('renders a by rows or columns select dropdown', () => {
      const wrapper = wrapperFactory(api)

      expect(wrapper.find('#by_rows_columns').exists()).toBe(true)
    })

    it('renders an offset tags by select number dropdown', () => {
      const wrapper = wrapperFactory(api)

      expect(wrapper.find('#start_at_tag_input').exists()).toBe(true)
    })

    // TODO tags per well test
    // it('renders a tags per well number based on the plate purpose', () => {
    // })
  })

  describe("#integration tests:", () => {
    it('sets selected on and disables the tag group selects when a tag plate is scanned', async () => {
      const wrapper = wrapperFactory(api)

      wrapper.vm.tagPlateScanned(goodQcableData)

      expect(wrapper.vm.tagPlate).toEqual(goodQcableData.plate)

      expect(wrapper.find('#tag1_group_selection').element.disabled).toBe(true)
      expect(wrapper.find('#tag2_group_selection').element.disabled).toBe(true)

      expect(wrapper.find('#tag1_group_selection').element.value).toEqual('1')
      expect(wrapper.find('#tag2_group_selection').element.value).toEqual('2')
    })

    it('updates tag1GroupId when a tag 1 group is selected', () => {
      const wrapper = wrapperFactory(api)

      expect(wrapper.vm.tag1GroupId).toEqual(null)

      wrapper.find('#tag1_group_selection').element.value = 1
      wrapper.find('#tag1_group_selection').trigger('change')

      expect(wrapper.vm.tag1GroupId).toBe(1)
    })

    it('updates tag2GroupId when a tag 2 group is selected', () => {
      const wrapper = wrapperFactory(api)

      expect(wrapper.vm.tag2GroupId).toEqual(null)

      wrapper.find('#tag2_group_selection').element.value = 1
      wrapper.find('#tag2_group_selection').trigger('change')

      expect(wrapper.vm.tag2GroupId).toBe(1)
    })

    it('re-enables the tag group selects when the tag plate is cleared', () => {
      const wrapper = wrapperFactory(api)

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
      const wrapper = wrapperFactory(api)

      expect(wrapper.vm.tagPlateScanDisabled).toBe(false)

      wrapper.find('#tag1_group_selection').element.value = 1
      wrapper.find('#tag1_group_selection').trigger('change')

      expect(wrapper.vm.tagPlateScanDisabled).toBe(true)

      expect(wrapper.find('#plateScan').element.disabled).toBe(true)
    })

    it('emits a call to the parent container on a change of the form data', () => {
      const wrapper = wrapperFactory(api)
      const emitted = wrapper.emitted()

      expect(wrapper.find('#by_pool_plate_options').exists()).toBe(true)

      const input = wrapper.find('#by_pool_plate_options')
      const option = input.find('option[value="by_plate_fixed"]')
      option.setSelected()
      input.trigger('input')

      expect(emitted.tagparamsupdated.length).toBe(1)
      expect(emitted.tagparamsupdated[0]).toEqual(
        [{'tag1GroupId':null,'tag2GroupId':null,'walkingBy':'by_plate_fixed','direction':'by_rows','startAtTagNumber':null}]
      )
    })

    // it('sends a post request when the create plate button is clicked', async () => {
    //   let mock = new MockAdapter(localVue.prototype.$axios)

    //   const plate = { state: 'valid', plate: plateFactory({ uuid: 'plate-uuid', _filledWells: 1 }) }
    //   const wrapper = wrapperFactory()
    //   wrapper.vm.updatePlate(1, plate)

    //   // Consider auto-selecting a single panel
    //   wrapper.setData({ primerPanel: 'Test panel' })

    //   const expectedPayload = { plate: {
    //     parent_uuid: 'plate-uuid',
    //     purpose_uuid: 'test',
    //     transfers: [
    //       { source_plate: 'plate-uuid', pool_index: 1, source_asset: 'plate-uuid-well-0', outer_request: 'plate-uuid-well-0-source-request-0', new_target: { location: 'A1' } }
    //     ]
    //   }}

    //   mockLocation.href = null
    //   mock.onPost().reply((config) =>{

    //     expect(config.url).toEqual('example/example')
    //     expect(config.data).toEqual(JSON.stringify(expectedPayload))
    //     return [201, { redirect: 'http://wwww.example.com', message: 'Creating...' }]
    //   })

    //   // Ideally we'd emit the event from the button component, but I'm having difficulty.
    //   wrapper.vm.createPlate()

    //   await flushPromises()

    //   expect(mockLocation.href).toEqual('http://wwww.example.com')
    // })
  })
})
