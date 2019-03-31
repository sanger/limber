// Import the component being tested
import { mount } from '@vue/test-utils'
import TagLayoutManipulationsMultiple from './TagLayoutManipulationsMultiple.vue'
import mockApi from 'test_support/mock_api'
import localVue from 'test_support/base_vue.js'

// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
describe('TagLayoutManipulationsMultiple', () => {
  const wrapperFactory = function(api = mockApi()) {
    return mount(TagLayoutManipulationsMultiple, {
      propsData: {
        api: api.devour,
        numberOfTags: 10,
        numberOfTargetWells: 10,
        tagsPerWell: 4
      },
      stubs: {
        'lb-tag-groups-lookup': true
      },
      localVue
    })
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

  describe('#computed function tests:', () => {
    describe('directionOptions:', () => {
      it('returns an array with the correct number of options', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.directionOptions.length).toBe(5)
      })
    })

    describe('offsetTagsByMax:', () => {
      it('returns expected value if tags and target wells exist', () => {
        const wrapper = wrapperFactory()

        wrapper.setProps({ numberOfTags: 5, numberOfTargetWells: 5 })

        expect(wrapper.vm.offsetTagsByMax).toBe(0)
        expect(wrapper.vm.offsetTagsByDisabled).toBe(true)
        expect(wrapper.vm.offsetTagsByPlaceholder).toBe('No spare tags...')
      })

      it('returns expected value if tags are in excess', () => {
        const wrapper = wrapperFactory()

        wrapper.setProps({ numberOfTags: 10, numberOfTargetWells: 5 })

        expect(wrapper.vm.offsetTagsByMax).toBe(5)
        expect(wrapper.vm.offsetTagsByDisabled).toBe(false)
        expect(wrapper.vm.offsetTagsByPlaceholder).toBe('Enter offset number...')
      })

      it('returns a negative number if there are not enough tags', () => {
        const wrapper = wrapperFactory()

        wrapper.setProps({ numberOfTags: 5, numberOfTargetWells: 10 })

        expect(wrapper.vm.offsetTagsByMax).toBe(-5)
        expect(wrapper.vm.offsetTagsByDisabled).toBe(true)
        expect(wrapper.vm.offsetTagsByPlaceholder).toBe('Not enough tags...')
      })

      it('returns null if there are no tags', () => {
        const wrapper = wrapperFactory()

        wrapper.setProps({ numberOfTags: 0, numberOfTargetWells: 5 })

        expect(wrapper.vm.offsetTagsByMax).toEqual(null)
        expect(wrapper.vm.offsetTagsByDisabled).toBe(true)
        expect(wrapper.vm.offsetTagsByPlaceholder).toBe('Select tags first...')
      })

      it('returns null if there are no target wells', () => {
        const wrapper = wrapperFactory()

        wrapper.setProps({ numberOfTags: 5, numberOfTargetWells: 0 })

        expect(wrapper.vm.offsetTagsByMax).toEqual(null)
        expect(wrapper.vm.offsetTagsByDisabled).toBe(true)
        expect(wrapper.vm.offsetTagsByPlaceholder).toBe('No target wells...')
      })
    })

    describe('offsetTagsByState:', () => {
      it('returns null if there is no start at tag number', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ offsetTagsBy: 0 })

        expect(wrapper.vm.offsetTagsByState).toEqual(null)
        expect(wrapper.vm.offsetTagsByValidFeedback).toEqual('')
      })

      it('returns null if the start at tag max is negative', () => {
        const wrapper = wrapperFactory()

        wrapper.setProps({ numberOfTags: 10, numberOfTargetWells: 20 })

        expect(wrapper.vm.offsetTagsByMax).toBe(-10)
        expect(wrapper.vm.offsetTagsByState).toEqual(null)
        expect(wrapper.vm.offsetTagsByValidFeedback).toEqual('')
      })

      it('returns true if the entered number is valid', () => {
        const wrapper = wrapperFactory()

        wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        wrapper.setData({ offsetTagsByMin: 1, offsetTagsBy: 5 })

        expect(wrapper.vm.offsetTagsByMax).toBe(9)
        expect(wrapper.vm.offsetTagsByState).toBe(true)
        expect(wrapper.vm.offsetTagsByValidFeedback).toEqual('Valid')
      })

      it('returns false if the entered number is too high', () => {
        const wrapper = wrapperFactory()

        wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        wrapper.setData({ offsetTagsByMin: 1, offsetTagsBy: 11 })

        expect(wrapper.vm.offsetTagsByMax).toBe(9)
        expect(wrapper.vm.offsetTagsByState).toBe(false)
        expect(wrapper.vm.offsetTagsByValidFeedback).toEqual('')
      })

      it('returns false if the entered number is too low', () => {
        const wrapper = wrapperFactory()

        wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        wrapper.setData({ offsetTagsByMin: 1, offsetTagsBy: 0 })

        expect(wrapper.vm.offsetTagsByMax).toBe(9)
        expect(wrapper.vm.offsetTagsByState).toBe(false)
        expect(wrapper.vm.offsetTagsByValidFeedback).toEqual('')
      })
    })

    describe('offsetTagsByInvalidFeedback:', () => {
      it('returns empty string if the entered number is null', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ offsetTagsBy: 0 })

        expect(wrapper.vm.offsetTagsByInvalidFeedback).toEqual('')
      })

      it('returns empty string if the max is not set', () => {
        const wrapper = wrapperFactory()

        wrapper.setProps({ numberOfTags: 0, numberOfTargetWells: 0 })
        wrapper.setData({ offsetTagsBy: 1 })

        expect(wrapper.vm.offsetTagsByMax).toEqual(null)
        expect(wrapper.vm.offsetTagsByInvalidFeedback).toEqual('')
      })

      it('returns empty string if the entered number is valid', () => {
        const wrapper = wrapperFactory()

        wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        wrapper.setData({ offsetTagsByMin: 1, offsetTagsBy: 5 })

        expect(wrapper.vm.offsetTagsByMax).toBe(9)
        expect(wrapper.vm.offsetTagsByInvalidFeedback).toEqual('')
      })

      it('returns correctly if the entered number is too high', () => {
        const wrapper = wrapperFactory()

        wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        wrapper.setData({ offsetTagsByMin: 1, offsetTagsBy: 11 })

        expect(wrapper.vm.offsetTagsByMax).toBe(9)
        expect(wrapper.vm.offsetTagsByInvalidFeedback).toEqual('Offset must be less than or equal to 9')
      })

      it('returns correctly if the entered number is too low', () => {
        const wrapper = wrapperFactory()

        wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        wrapper.setData({ offsetTagsByMin: 1, offsetTagsBy: 0 })

        expect(wrapper.vm.offsetTagsByMax).toBe(9)
        expect(wrapper.vm.offsetTagsByInvalidFeedback).toEqual('Offset must be greater than or equal to 1')
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
  })

  describe('#rendering tests:', () => {
    it('renders a vue instance', () => {
      const wrapper = wrapperFactory()

      expect(wrapper.isVueInstance()).toBe(true)
    })

    it('renders a tag1 group select dropdown', () => {
      const wrapper = wrapperFactory()

      expect(wrapper.find('#tag1_group_selection').exists()).toBe(true)
      expect(wrapper.find('#tag1_group_selection').element.disabled).toBe(false)
      expect(wrapper.find('#tag1_group_selection').element.value).toEqual('')
    })

    it('renders a walking by label', () => {
      const wrapper = wrapperFactory()

      expect(wrapper.find('#walking_by_label').exists()).toBe(true)
    })

    it('renders a direction select dropdown', () => {
      const wrapper = wrapperFactory()

      expect(wrapper.find('#direction_options').exists()).toBe(true)
    })

    it('renders an offset tags by select number input', () => {
      const wrapper = wrapperFactory()

      expect(wrapper.find('#offset_tags_by_input').exists()).toBe(true)
    })
  })

  describe('#integration tests:', () => {
    it('updates tag1GroupId when a tag 1 group is selected', () => {
      const wrapper = wrapperFactory()

      wrapper.setData({ tagGroupsList: goodTagGroupsList })

      expect(wrapper.vm.tag1GroupId).toEqual(null)

      wrapper.find('#tag1_group_selection').element.value = '1'
      wrapper.find('#tag1_group_selection').trigger('change') // TODO needed?

      expect(wrapper.vm.tag1GroupId).toBe('1')
    })

    it('emits a call to the parent container on a change of the form data', () => {
      const wrapper = wrapperFactory()
      const emitted = wrapper.emitted()

      expect(wrapper.find('#direction_options').exists()).toBe(true)

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
          walkingBy: 'as group by plate',
          direction: 'row',
          offsetTagsBy: 0
        }
      ]

      const input = wrapper.find('#direction_options')
      const option = input.find('option[value="row"]')
      option.setSelected()
      input.trigger('input')

      expect(emitted.tagparamsupdated.length).toBe(1)
      expect(emitted.tagparamsupdated[0]).toEqual(expectedEmitted)
    })
  })
})
