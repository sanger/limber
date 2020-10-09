// Import the component being tested
import { shallowMount } from '@vue/test-utils'
import TagLayoutManipulations from './TagLayoutManipulations.vue'
import localVue from 'test_support/base_vue.js'
import {
  nullQcableData,
  exampleQcableData,
  exampleTagGroupsList
} from 'custom-tagged-plate/testData/customTaggedPlateTestData.js'

// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
describe('TagLayoutManipulations', () => {
  const wrapperFactory = function() {
    return shallowMount(TagLayoutManipulations, {
      propsData: {
        api: {},
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

  describe('#computed function tests:', () => {
    describe('walkingByOptions:', () => {
      it('returns an array with the correct number of options for standard plates', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.walkingByOptions.length).toBe(4)
      })
    })

    describe('tagGroupsDisabled:', () => {
      it('returns false if a tag plate has not been scanned', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ tagPlate: null })

        expect(wrapper.vm.tagGroupsDisabled).toBe(false)
      })

      it('returns true if a valid tag plate was scanned', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ tagPlate: exampleQcableData.plate })

        expect(wrapper.vm.tagGroupsDisabled).toBe(true)
      })
    })
  })

  describe('#rendering tests:', () => {
    it('renders a tag plate scan component', () => {
      const wrapper = wrapperFactory()

      expect(wrapper.find('#tag_plate_scan').exists()).toBe(true)
    })

    it('renders a tag1 group select dropdown', () => {
      const wrapper = wrapperFactory()

      expect(wrapper.find('#tag1_group_selection').exists()).toBe(true)
    })

    it('renders a tag2 group select dropdown', () => {
      const wrapper = wrapperFactory()

      expect(wrapper.find('#tag2_group_selection').exists()).toBe(true)
    })

    it('renders a walking by select dropdown', () => {
      const wrapper = wrapperFactory()

      expect(wrapper.find('#walking_by_options').exists()).toBe(true)
    })

    it('renders a direction select dropdown', () => {
      const wrapper = wrapperFactory()

      expect(wrapper.find('#direction_options').exists()).toBe(true)
    })
  })

  describe('#integration tests:', () => {
    it('sets selected on and disables the tag group selects when a tag plate is scanned', async () => {
      const wrapper = wrapperFactory()

      wrapper.setData({ tagGroupsList: exampleTagGroupsList })

      wrapper.vm.tagPlateScanned(exampleQcableData)

      expect(wrapper.vm.tagPlate).toEqual(exampleQcableData.plate)

      // NB cannot check the vue bootstrap elements directly with shallowMount
      // wrapper
      expect(wrapper.vm.tagGroupsDisabled).toBe(true)
    })

    it('re-enables the tag group selects when the tag plate is cleared', () => {
      const wrapper = wrapperFactory()

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
      const wrapper = wrapperFactory()

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
      const wrapper = wrapperFactory()
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

      // NB. cannot interact with vue bootstrap components when wrapper is
      // shallowMounted
      wrapper.vm.updateTagParams()

      expect(emitted.tagparamsupdated.length).toBe(1)
      expect(emitted.tagparamsupdated[0]).toEqual(expectedEmitted)
    })
  })
})
