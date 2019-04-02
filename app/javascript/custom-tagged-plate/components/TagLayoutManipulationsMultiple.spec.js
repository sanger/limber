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
        'lb-tag-groups-lookup': true,
        'lb-tag-offset': true
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

  const nullTagGroup = {
    uuid: null,
    name: 'No tag group selected',
    tags: []
  }

  describe('#computed function tests:', () => {
    describe('directionOptions:', () => {
      it('returns an array with the correct number of options', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.directionOptions.length).toBe(5)
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

    describe('tag1Group:', () => {
      it('returns a valid tag 1 group if the id matches a group in the list', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          tagGroupsList: goodTagGroupsList,
          tag1GroupId: 1
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

    describe('walkingByDisplayed:', () => {
      it('returns the correct text if walking by matches expected value', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ walkingBy: 'as group by plate' })

        expect(wrapper.vm.walkingByDisplayed).toEqual('Apply Multiple Tags')
      })

      it('returns the correct text if walking by is any other value', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ walkingBy: 'some value' })

        expect(wrapper.vm.walkingByDisplayed).toEqual('some value')
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
