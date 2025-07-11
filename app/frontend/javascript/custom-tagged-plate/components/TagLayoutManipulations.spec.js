// Import the component being tested
import { mount } from '@vue/test-utils'
import TagLayoutManipulations from './TagLayoutManipulations.vue'
import {
  exampleQcableData,
  exampleTagGroupsList,
  exampleTagSetList,
} from '@/javascript/custom-tagged-plate/testData/customTaggedPlateTestData.js'
import { expect } from 'vitest'

describe('TagLayoutManipulations', () => {
  const wrapperFactory = function () {
    return mount(TagLayoutManipulations, {
      props: {
        api: {},
        numberOfTags: 10,
        numberOfTargetWells: 10,
        tagsPerWell: 1,
      },
      global: {
        stubs: {
          'lb-plate-scan': true,
          TagGroupsLookup: true,
          'lb-tag-offset': true,
        },
      },
    })
  }

  describe('#computed function tests:', () => {
    describe('walkingByOptions:', () => {
      it('returns an array with the correct number of options for standard plates', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.walkingByOptions.length).toBe(4)
      })
    })

    describe('tagSetsDisabled:', () => {
      it('returns false if a tag plate has not been scanned', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ tagPlate: null })
        expect(wrapper.vm.tagSetsDisabled).toBe(false)
      })

      it('returns true if a valid tag plate was scanned', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ tagPlate: exampleQcableData.plate })
        expect(wrapper.vm.tagSetsDisabled).toBe(true)
      })
    })
  })

  describe('#rendering tests:', () => {
    it('renders a tag plate scan component', () => {
      const wrapper = wrapperFactory()

      expect(wrapper.find('#tag_plate_scan').exists()).toBe(true)
    })

    it('renders a tag set selection dropdown', () => {
      const wrapper = wrapperFactory()
      expect(wrapper.find('#tag_set_selection').exists()).toBe(true)
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
    it('sets selected on and disables the tag set selects when a tag plate is scanned', async () => {
      const wrapper = wrapperFactory()
      wrapper.setData({ tagSetList: exampleTagSetList })

      wrapper.vm.tagPlateScanned(exampleQcableData)

      expect(wrapper.vm.tagPlate).toEqual(exampleQcableData.plate)

      // NB cannot check the vue bootstrap elements directly with shallowMount
      // wrapper
      expect(wrapper.vm.tagSetsDisabled).toBe(true)
    })

    it('reenables the tag plate scan input if the tag group 1 and 2 is cleared', () => {
      const wrapper = wrapperFactory()

      wrapper.setData({ tagGroupsList: exampleTagGroupsList })

      expect(wrapper.vm.tagPlateScanDisabled).toBe(false)

      //Set a tag group and this disables the tagPlate scan
      wrapper.setData({ tag1GroupId: 1 })
      wrapper.vm.tagGroupChanged()
      wrapper.vm.tagGroupInput()
      expect(wrapper.vm.tagPlateScanDisabled).toBe(true)

      //Remove tag group  selection and this re-enables the tagPlate scan
      wrapper.setData({ tag1GroupId: null, tag2GroupId: null })
      wrapper.vm.tagGroupChanged()
      wrapper.vm.tagGroupInput()
      expect(wrapper.vm.tagPlateScanDisabled).toBe(false)

      wrapper.vm.tagGroupChanged()
    })

    it('disables the tag plate scan input if a tagset is selected', () => {
      const wrapper = wrapperFactory()

      wrapper.setData({ tagSetList: exampleTagSetList })

      expect(wrapper.vm.tagPlateScanDisabled).toBe(false)

      wrapper.setData({ tagSetId: 1 })

      wrapper.vm.tagSetChanged()
      expect(wrapper.vm.tag1GroupId).toBe(exampleTagSetList[1].tag_group.id)
      expect(wrapper.vm.tag2GroupId).toBe(exampleTagSetList[1].tag2_group.id)

      expect(wrapper.vm.tagPlateScanDisabled).toBe(true)
    })

    it('reenables the tag plate scan input if the tagset is cleared', () => {
      const wrapper = wrapperFactory()
      wrapper.setData({ tagSetList: exampleTagSetList })
      expect(wrapper.vm.tagPlateScanDisabled).toBe(false)

      //Set a tag set and this disables the tagPlate scan
      wrapper.setData({ tagSetId: 1 })
      wrapper.vm.tagSetChanged()
      expect(wrapper.vm.tagPlateScanDisabled).toBe(true)

      //Remove tag set  selection and this re-enables the tagPlate scan
      wrapper.setData({ tagSetId: null })
      wrapper.vm.tagSetChanged()
      expect(wrapper.vm.tagPlateScanDisabled).toBe(false)

      wrapper.vm.tagGroupChanged()
    })

    it('emits a call to the parent container on a change of the form data', () => {
      const wrapper = wrapperFactory()

      wrapper.setData({ walkingBy: 'manual by plate' })

      const expectedEmitted = [
        {
          tagPlate: null,
          tag1Group: {
            uuid: null,
            name: 'No tag group selected',
            tags: [],
          },
          tag2Group: {
            uuid: null,
            name: 'No tag group selected',
            tags: [],
          },
          walkingBy: 'manual by plate',
          direction: 'column',
          offsetTagsBy: 0,
        },
      ]

      wrapper.vm.updateTagParams()
      const emitted = wrapper.emitted()

      expect(emitted.tagparamsupdated.length).toBe(1)
      expect(emitted.tagparamsupdated[0]).toEqual(expectedEmitted)
    })
  })
})
