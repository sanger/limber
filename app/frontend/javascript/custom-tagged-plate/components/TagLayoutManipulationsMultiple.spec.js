// Import the component being tested
import { mount } from '@vue/test-utils'
import TagLayoutManipulationsMultiple from './TagLayoutManipulationsMultiple.vue'

// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
describe('TagLayoutManipulationsMultiple', () => {
  const wrapperFactory = function () {
    return mount(TagLayoutManipulationsMultiple, {
      props: {
        api: {},
        numberOfTags: 10,
        numberOfTargetWells: 10,
        tagsPerWell: 4,
      },
      global: {
        stubs: {
          'tag-groups-lookup': true,
          'lb-tag-offset': true,
        },
      },
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

      wrapper.setData({ direction: 'row' })

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
          walkingBy: 'as fixed group by plate',
          direction: 'row',
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
