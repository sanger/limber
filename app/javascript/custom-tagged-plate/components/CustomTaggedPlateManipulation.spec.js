// Import the component being tested
import { mount, shallowMount } from '@vue/test-utils'
import CustomTaggedPlateManipulation from './CustomTaggedPlateManipulation.vue'
import mockApi from 'test_support/mock_api'
import localVue from 'test_support/base_vue.js'

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
        numberOfTags: 10,
        numberOfTargetWells: 10,
        tagsPerWell: 1
      },
      localVue
    })
  }

  const nullQcable = { data: [] }
  const emptyQcableData = { plate: null, state: 'empty' }
  const goodQcableData = {
    plate: {
      id:'1',
      labware_barcode: {
        human_barcode: 'TG12345678'
      },
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

  describe('#computed function tests:', () => {
    describe('walkingByOptions:', () => {
      it('returns an array with the correct number of options for standard plates', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ tagsPerWell: 1 })

        expect(wrapper.vm.walkingByOptions.length).toBe(4)
      })

      it('returns an array with the correct number of options for chromium plates', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ tagsPerWell: 4 })

        expect(wrapper.vm.walkingByOptions.length).toBe(1)
      })
    })

    describe('directionOptions:', () => {
      it('returns an array with the correct number of options', () => {
        const wrapper = wrapperFactory(api)

        expect(wrapper.vm.directionOptions.length).toBe(5)
      })
    })

    describe('tagGroupsDisabled:', () => {
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

    describe('offsetTagByMax:', () => {
      it('returns expected value if tags and target wells exist', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 5, numberOfTargetWells: 5 })

        expect(wrapper.vm.offsetTagByMax).toBe(0)
        expect(wrapper.vm.offsetTagByDisabled).toBe(true)
        expect(wrapper.vm.offsetTagByPlaceholder).toBe('No spare tags...')
      })

      it('returns expected value if tags are in excess', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 10, numberOfTargetWells: 5 })

        expect(wrapper.vm.offsetTagByMax).toBe(5)
        expect(wrapper.vm.offsetTagByDisabled).toBe(false)
        expect(wrapper.vm.offsetTagByPlaceholder).toBe('Enter offset number...')
      })

      it('returns a negative number if there are not enough tags', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 5, numberOfTargetWells: 10 })

        expect(wrapper.vm.offsetTagByMax).toBe(-5)
        expect(wrapper.vm.offsetTagByDisabled).toBe(true)
        expect(wrapper.vm.offsetTagByPlaceholder).toBe('Not enough tags...')
      })

      it('returns null if there are no tags', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 0, numberOfTargetWells: 5 })

        expect(wrapper.vm.offsetTagByMax).toEqual(null)
        expect(wrapper.vm.offsetTagByDisabled).toBe(true)
        expect(wrapper.vm.offsetTagByPlaceholder).toBe('Select tags first...')
      })

      it('returns null if there are no target wells', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 5, numberOfTargetWells: 0 })

        expect(wrapper.vm.offsetTagByMax).toEqual(null)
        expect(wrapper.vm.offsetTagByDisabled).toBe(true)
        expect(wrapper.vm.offsetTagByPlaceholder).toBe('No target wells...')
      })
    })

    describe('offsetTagByState:', () => {
      it('returns null if there is no start at tag number', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setData({ offsetTagByNumber: 0 })

        expect(wrapper.vm.offsetTagByState).toEqual(null)
        expect(wrapper.vm.offsetTagByValidFeedback).toEqual('')
      })

      it('returns null if the start at tag max is negative', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 10, numberOfTargetWells: 20 })

        expect(wrapper.vm.offsetTagByMax).toBe(-10)
        expect(wrapper.vm.offsetTagByState).toEqual(null)
        expect(wrapper.vm.offsetTagByValidFeedback).toEqual('')
      })

      it('returns true if the entered number is valid', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        wrapper.setData({ offsetTagByMin: 1, offsetTagByNumber: 5 })

        expect(wrapper.vm.offsetTagByMax).toBe(9)
        expect(wrapper.vm.offsetTagByState).toBe(true)
        expect(wrapper.vm.offsetTagByValidFeedback).toEqual('Valid')
      })

      it('returns false if the entered number is too high', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        wrapper.setData({ offsetTagByMin: 1, offsetTagByNumber: 11 })

        expect(wrapper.vm.offsetTagByMax).toBe(9)
        expect(wrapper.vm.offsetTagByState).toBe(false)
        expect(wrapper.vm.offsetTagByValidFeedback).toEqual('')
      })

      it('returns false if the entered number is too low', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        wrapper.setData({ offsetTagByMin: 1, offsetTagByNumber: 0 })

        expect(wrapper.vm.offsetTagByMax).toBe(9)
        expect(wrapper.vm.offsetTagByState).toBe(false)
        expect(wrapper.vm.offsetTagByValidFeedback).toEqual('')
      })
    })

    describe('offsetTagByInvalidFeedback:', () => {
      it('returns empty string if the entered number is null', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setData({ offsetTagByNumber: 0 })

        expect(wrapper.vm.offsetTagByInvalidFeedback).toEqual('')
      })

      it('returns empty string if the max is not set', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 0, numberOfTargetWells: 0 })
        wrapper.setData({ offsetTagByNumber: 1 })

        expect(wrapper.vm.offsetTagByMax).toEqual(null)
        expect(wrapper.vm.offsetTagByInvalidFeedback).toEqual('')
      })

      it('returns empty string if the entered number is valid', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        wrapper.setData({ offsetTagByMin: 1, offsetTagByNumber: 5 })

        expect(wrapper.vm.offsetTagByMax).toBe(9)
        expect(wrapper.vm.offsetTagByInvalidFeedback).toEqual('')
      })

      it('returns correctly if the entered number is too high', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        wrapper.setData({ offsetTagByMin: 1, offsetTagByNumber: 11 })

        expect(wrapper.vm.offsetTagByMax).toBe(9)
        expect(wrapper.vm.offsetTagByInvalidFeedback).toEqual('Offset must be less than or equal to 9')
      })

      it('returns correctly if the entered number is too low', () => {
        const wrapper = wrapperFactory(api)

        wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        wrapper.setData({ offsetTagByMin: 1, offsetTagByNumber: 0 })

        expect(wrapper.vm.offsetTagByMax).toBe(9)
        expect(wrapper.vm.offsetTagByInvalidFeedback).toEqual('Offset must be greater than or equal to 1')
      })
    })
  })

  describe('#rendering tests:', () => {
    it('renders a vue instance', () => {
      const wrapper = wrapperFactory(api)

      expect(wrapper.isVueInstance()).toBe(true)
    })

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

    it('renders a walking by select dropdown', () => {
      const wrapper = wrapperFactory(api)

      expect(wrapper.find('#walking_by_options').exists()).toBe(true)
    })

    it('renders a direction select dropdown', () => {
      const wrapper = wrapperFactory(api)

      expect(wrapper.find('#direction_options').exists()).toBe(true)
    })

    it('renders an offset tags by select number input', () => {
      const wrapper = wrapperFactory(api)

      expect(wrapper.find('#offset_tags_by_input').exists()).toBe(true)
    })
  })

  describe('#integration tests:', () => {
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

      expect(wrapper.find('#walking_by_options').exists()).toBe(true)

      const input = wrapper.find('#walking_by_options')
      const option = input.find('option[value="wells of plate"]')
      option.setSelected()
      input.trigger('input')

      expect(emitted.tagparamsupdated.length).toBe(1)
      expect(emitted.tagparamsupdated[0]).toEqual(
        [{'tagPlate':null,'tag1GroupId':null,'tag2GroupId':null,'walkingBy':'wells of plate','direction':'row','offsetTagByNumber':0}]
      )
    })
  })
})
