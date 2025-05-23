import { mount, flushPromises } from '@vue/test-utils'
import TagSetsLookup from '@/javascript/shared/components/TagSetsLookup.vue'
import { jsonCollectionFactory } from '@/javascript/test_support/factories.js'
import mockApi from '@/javascript/test_support/mock_api.js'

describe('TagSetsLookup', () => {
  const tagSetObject = {
    1: {
      id: '1',
      type: 'tag_sets',
      uuid: 'tag-set-1-uuid',
      name: 'Tag Set 1',
      tag_group: {
        id: '1',
        uuid: 'tag-1-group-uuid',
        name: 'Tag Group 1',
        type: 'tag_groups',
        tags: [
          {
            index: 1,
            oligo: 'CTAGCTAG',
          },
          {
            index: 2,
            oligo: 'TTATACGA',
          },
        ],
        tag_group_adapter_type: 'Chromium',
      },
      tag2_group: {
        id: '2',
        uuid: 'tag-2-group-uuid',
        type: 'tag_groups',
        name: 'Tag Group 2',
        tags: [
          {
            index: 2,
            oligo: 'AATTCGCA',
          },
          {
            index: 1,
            oligo: 'CCTTAAGG',
          },
        ],
      },
    },
    2: {
      id: '2',
      type: 'tag_sets',
      uuid: 'tag-set-2-uuid',
      name: 'Tag Set 2',
      tag_group: {
        id: '1',
        uuid: 'tag-1-group-uuid',
        name: 'Tag Group 1',
        tags: [
          {
            index: 1,
            oligo: 'CTAGCTAG',
          },
          {
            index: 2,
            oligo: 'TTATACGA',
          },
        ],
      },
      tag2_group: {
        id: '2',
        uuid: 'tag-2-group-uuid',
        name: 'Tag Group 2',
        tags: [
          {
            index: 2,
            oligo: 'AATTCGCA',
          },
          {
            index: 1,
            oligo: 'CCTTAAGG',
          },
        ],
      },
    },
  }

  const tagSetArray = Object.values(tagSetObject)

  const tagSets = jsonCollectionFactory('tag_set', tagSetArray)
  const emptyTagSet = jsonCollectionFactory('tag_set', [])

  const wrapperFactory = function (api = mockApi()) {
    return mount(TagSetsLookup, {
      propsData: {
        api: api.devour,
        resourceName: 'tag_set',
      },
    })
  }
  const extractRelevantProperties = (array) =>
    array.map((tagSet) => ({
      id: tagSet.id,
      uuid: tagSet.uuid,
      name: tagSet.name,
      tag_group: {
        id: tagSet.tag_group.id,
        uuid: tagSet.tag_group.uuid,
        name: tagSet.tag_group.name,
        tags: tagSet.tag_group.tags.sort((a, b) => a.index - b.index),
      },
      tag2_group: {
        id: tagSet.tag2_group.id,
        uuid: tagSet.tag2_group.uuid,
        name: tagSet.tag2_group.name,
        tags: tagSet.tag2_group.tags.sort((a, b) => a.index - b.index),
      },
    }))

  it('is invalid if it can not find any tag sets', async () => {
    const api = mockApi()

    api.mockGet('tag_sets', { filter: {}, page: { number: 1, size: 150 }, include: '' }, emptyTagSet)

    const wrapper = wrapperFactory(api)

    expect(wrapper.vm.state).toEqual('searching')

    await flushPromises()

    expect(wrapper.vm.feedback).toEqual('No results retrieved')
    expect(wrapper.emitted()).toEqual({
      change: [[{ state: 'invalid', results: {} }]],
    })
  })

  it('is valid if it can find tag sets and tag groups with tags sorted in order of index', async () => {
    const api = mockApi()

    api.mockGet('tag_sets', { filter: {}, page: { number: 1, size: 150 }, include: '' }, tagSets)

    const wrapper = wrapperFactory(api)

    expect(wrapper.vm.state).toEqual('searching')

    await flushPromises()

    expect(wrapper.vm.state).toEqual('valid')

    const events = wrapper.emitted()

    expect(events.change.length).toEqual(1)
    expect(events.change[0][0].state).toEqual('valid')

    expect(extractRelevantProperties(Object.values(events.change[0][0].results))).toEqual(
      extractRelevantProperties(tagSetArray),
    )
  })
})
