// Import the component being tested
import { shallowMount } from '@vue/test-utils'
import TagLayoutManipulations from './TagLayoutManipulations.vue'
import mockApi from 'test_support/mock_api'
import localVue from 'test_support/base_vue.js'
import {
  nullTagGroup,
  nullQcableData,
  exampleQcableData,
  exampleTagGroupsList
} from '../testData/customTaggedPlateTestData.js'

// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
describe('TagLayoutManipulations', () => {
  const wrapperFactory = function(api = mockApi()) {
    return shallowMount(TagLayoutManipulations, {
      propsData: {
        api: api.devour,
        numberOfTags: 10,
        numberOfTargetWells: 10,
        tagsPerWell: 1
      },
      stubs: {
        'lb-plate-scan': true,
        'lb-tag-groups-lookup': true,
        'lb-tag-offset': true
      },
      localVue
    })
  }

  const api = mockApi()
  api.mockGet('qcables', {
    filter: {
      barcode: 'somebarcode'
    },
    include: 'asset,lot,lot.tag_layout_template,lot.tag_layout_template.tag_group,lot.tag_layout_template.tag2_group',
    fields: {
      assets: 'uuid',
      lots: 'uuid,tag_layout_template',
      tag_layout_templates: 'uuid,tag_group,tag2_group,direction,walking_by',
      tag_group: 'uuid,name,tags'
    }
  }, { data: [] })

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

        wrapper.setData({ tagPlate: exampleQcableData.plate })

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

        wrapper.setData({ tagGroupsList: exampleTagGroupsList })

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

        wrapper.setData({ tagGroupsList: exampleTagGroupsList })

        const goodTag2GroupOptions = [
          { value: null, text: 'Please select an i5 Tag 2 group...' },
          { value: '1', text: 'Tag Group 1' },
          { value: '2', text: 'Tag Group 2' }
        ]

        expect(wrapper.vm.tag2GroupOptions).toEqual(goodTag2GroupOptions)
      })
    })

    describe('tag1Group:', () => {
      it('returns a valid tag 1 group if the id matches a group in the list', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          tagGroupsList: exampleTagGroupsList,
          tag1GroupId: '1'
        })

        const expectedTagGroup = {
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
        }

        expect(wrapper.vm.tag1Group).toEqual(expectedTagGroup)
      })

      it('returns a null tag 1 group otherwise', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.tag1Group).toEqual(nullTagGroup)
      })
    })

    describe('tag2Group:', () => {
      it('returns a valid tag 2 group if the id matches a group in the list', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          tagGroupsList: exampleTagGroupsList,
          tag2GroupId: 1
        })

        const expectedTagGroup = {
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
        }

        expect(wrapper.vm.tag2Group).toEqual(expectedTagGroup)
      })

      it('returns a null tag 2 group otherwise', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.tag2Group).toEqual(nullTagGroup)
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
    })

    it('renders a tag2 group select dropdown', () => {
      const wrapper = wrapperFactory(api)

      expect(wrapper.find('#tag2_group_selection').exists()).toBe(true)
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

      wrapper.setData({ tagGroupsList: exampleTagGroupsList })

      wrapper.vm.tagPlateScanned(exampleQcableData)

      expect(wrapper.vm.tagPlate).toEqual(exampleQcableData.plate)

      // NB cannot check the vue bootstrap elements directly with shallowMount
      // wrapper
      expect(wrapper.vm.tagGroupsDisabled).toBe(true)
    })

    it('re-enables the tag group selects when the tag plate is cleared', () => {
      const wrapper = wrapperFactory(api)

      wrapper.setData({ tagGroupsList: exampleTagGroupsList })

      wrapper.vm.tagPlateScanned(exampleQcableData)

      // NB cannot check the vue bootstrap elements directly with shallowMount
      // wrapper
      expect(wrapper.vm.tagGroupsDisabled).toBe(true)

      wrapper.vm.tagPlateScanned(nullQcableData)

      expect(wrapper.vm.tagGroupsDisabled).toBe(false)

      expect(wrapper.vm.tag1GroupId).toEqual(null)
      expect(wrapper.vm.tag2GroupId).toEqual(null)
      expect(wrapper.vm.tagPlate).toEqual(null)
    })

    it('disables the tag plate scan input if a tag group 1 or 2 is selected', () => {
      const wrapper = wrapperFactory(api)

      wrapper.setData({ tagGroupsList: exampleTagGroupsList })

      expect(wrapper.vm.tagPlateScanDisabled).toBe(false)

      // NB cannot check the vue bootstrap elements directly with shallowMount
      // wrapper
      wrapper.setData({ tag1GroupId: 1 })

      wrapper.vm.tagGroupChanged()
      wrapper.vm.tagGroupInput()

      expect(wrapper.vm.tagPlateScanDisabled).toBe(true)
    })

    it('emits a call to the parent container on a change of the form data', () => {
      const wrapper = wrapperFactory(api)
      const emitted = wrapper.emitted()

      wrapper.setData({ walkingBy: 'manual by plate' })

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
          walkingBy: 'manual by plate',
          direction: 'column',
          offsetTagsBy: 0
        }
      ]

      // NB. cannot interact with vue bootstrap components as would like
      wrapper.vm.updateTagParams()

      expect(emitted.tagparamsupdated.length).toBe(1)
      expect(emitted.tagparamsupdated[0]).toEqual(expectedEmitted)
    })
  })
})
