// Import the component being tested
import { mount } from '@vue/test-utils'
import TagLayoutManipulations from './TagLayoutManipulations.vue'
import mockApi from 'test_support/mock_api'
import localVue from 'test_support/base_vue.js'

// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
describe('TagLayoutManipulations', () => {
  const wrapperFactory = function(api = mockApi()) {
    return mount(TagLayoutManipulations, {
      propsData: {
        api: api.devour,
        numberOfTags: 10,
        numberOfTargetWells: 10,
        tagsPerWell: 1
      },
      stubs: {
        // 'lb-plate-scan': true,
        'lb-tag-groups-lookup': true,
        'lb-tag-offset': true
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
  const goodTagGroupsList = {
    1: {
      id: '1',
      uuid: 'tag-1-group-uuid',
      name: 'Tag Group 1',
      tags: [
        {
          index: 1,
          oligo: 'CTAGCTAG'
        },
        {
          index: 2,
          oligo: 'TTATACGA'
        }
      ]
    },
    2: {
      id: '2',
      uuid: 'tag-2-group-uuid',
      name: 'Tag Group 2',
      tags: [
        {
          index: 1,
          oligo: 'CCTTAAGG'
        },
        {
          index: 2,
          oligo: 'AATTCGCA'
        }
      ]
    }
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

        expect(wrapper.vm.walkingByOptions.length).toBe(4)
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

    describe('tag1GroupOptions:', () => {
      it('returns empty array for tag 1 groups if tag groups list empty', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.tag1GroupOptions).toEqual([{ value: null, text: 'Please select an i7 Tag 1 group...' }])
      })

      it('returns valid array of tag 1 groups if tag groups list set', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ tagGroupsList: goodTagGroupsList })

        const goodTag1GroupOptions = [
          { value: null, text: 'Please select an i7 Tag 1 group...' },
          { value: '1', text: 'Tag Group 1' },
          { value: '2', text: 'Tag Group 2' }
        ]

        expect(wrapper.vm.tag1GroupOptions).toEqual(goodTag1GroupOptions)
      })
    })

    describe('tag2GroupOptions:', () => {
      it('returns empty array for tag 2 groups if tag groups list empty', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.tag2GroupOptions).toEqual([{ value: null, text: 'Please select an i5 Tag 2 group...' }])
      })

      it('returns valid array of tag 2 groups if tag groups list set', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ tagGroupsList: goodTagGroupsList })

        const goodTag2GroupOptions = [
          { value: null, text: 'Please select an i5 Tag 2 group...' },
          { value: '1', text: 'Tag Group 1' },
          { value: '2', text: 'Tag Group 2' }
        ]

        expect(wrapper.vm.tag2GroupOptions).toEqual(goodTag2GroupOptions)
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
  })

  describe('#integration tests:', () => {
    it('sets selected on and disables the tag group selects when a tag plate is scanned', async () => {
      const wrapper = wrapperFactory(api)

      wrapper.setData({ tagGroupsList: goodTagGroupsList })

      wrapper.vm.tagPlateScanned(goodQcableData)

      expect(wrapper.vm.tagPlate).toEqual(goodQcableData.plate)

      expect(wrapper.find('#tag1_group_selection').element.disabled).toBe(true)
      expect(wrapper.find('#tag2_group_selection').element.disabled).toBe(true)

      expect(wrapper.find('#tag1_group_selection').element.value).toEqual('1')
      expect(wrapper.find('#tag2_group_selection').element.value).toEqual('2')
    })

    it('updates tag1GroupId when a tag 1 group is selected', () => {
      const wrapper = wrapperFactory(api)

      wrapper.setData({ tagGroupsList: goodTagGroupsList })

      expect(wrapper.vm.tag1GroupId).toEqual(null)

      wrapper.find('#tag1_group_selection').element.value = '1'
      wrapper.find('#tag1_group_selection').trigger('change')

      expect(wrapper.vm.tag1GroupId).toBe('1')
    })

    it('updates tag2GroupId when a tag 2 group is selected', () => {
      const wrapper = wrapperFactory(api)

      wrapper.setData({ tagGroupsList: goodTagGroupsList })

      expect(wrapper.vm.tag2GroupId).toEqual(null)

      wrapper.find('#tag2_group_selection').element.value = '1'
      wrapper.find('#tag2_group_selection').trigger('change')

      expect(wrapper.vm.tag2GroupId).toBe('1')
    })

    it('re-enables the tag group selects when the tag plate is cleared', () => {
      const wrapper = wrapperFactory(api)

      wrapper.setData({ tagGroupsList: goodTagGroupsList })

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

      wrapper.setData({ tagGroupsList: goodTagGroupsList })

      expect(wrapper.vm.tagPlateScanDisabled).toBe(false)

      wrapper.find('#tag1_group_selection').element.value = 1
      wrapper.find('#tag1_group_selection').trigger('change')

      expect(wrapper.vm.tagPlateScanDisabled).toBe(true)

      expect(wrapper.find('#tag_plate_scan').vm.scanDisabled).toBe(true)
    })

    it('emits a call to the parent container on a change of the form data', () => {
      const wrapper = wrapperFactory(api)
      const emitted = wrapper.emitted()

      expect(wrapper.find('#walking_by_options').exists()).toBe(true)

      const expectedEmitted = [
        {
          tagPlate: null,
          tag1Group: {
            uuid: null,
            name: 'No tag group selected',
            tags: []
          },
          tag2Group: {
            uuid: null,
            name: 'No tag group selected',
            tags: []
          },
          walkingBy: 'wells of plate',
          direction: 'column',
          offsetTagsBy: 0
        }
      ]

      const input = wrapper.find('#walking_by_options')
      const option = input.find('option[value="wells of plate"]')
      option.setSelected()
      input.trigger('input')

      expect(emitted.tagparamsupdated.length).toBe(1)
      expect(emitted.tagparamsupdated[0]).toEqual(expectedEmitted)
    })
  })
})
