// Import the component being tested
import { shallowMount } from '@vue/test-utils'
import TagLayoutManipulationsMultiple from './TagLayoutManipulationsMultiple.vue'
import localVue from 'test_support/base_vue.js'

// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
describe('TagLayoutManipulationsMultiple', () => {
  const wrapperFactory = function() {
    return shallowMount(TagLayoutManipulationsMultiple, {
      propsData: {
        api: {},
        numberOfTags: 10,
        numberOfTargetWells: 10,
        tagsPerWell: 4
      },
      stubs: {
        'lb-tag-groups-lookup': true,
        'lb-tag-offset': true
      },
      localVue
    })
  }

  describe('#computed function tests:', () => {
    describe('walkingByOptions:', () => {
      it('returns an array with the correct number of options', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.walkingByOptions.length).toBe(3)
      })
    })
  })

  describe('#rendering tests:', () => {
    it('renders a tag1 group select dropdown', () => {
      const wrapper = wrapperFactory()

      expect(wrapper.find('#tag1_group_selection').exists()).toBe(true)
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
    it('emits a call to the parent container on a change of the form data', () => {
      const wrapper = wrapperFactory()
      const emitted = wrapper.emitted()

      wrapper.setData({ direction: 'row' })

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
          walkingBy: 'as fixed group by plate',
          direction: 'row',
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
