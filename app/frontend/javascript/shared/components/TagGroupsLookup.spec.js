import { mount } from '@vue/test-utils'
import { flushPromises } from '@vue/test-utils'
import TagGroupsLookup from '@/javascript/shared/components/TagGroupsLookup.vue'
import { jsonCollectionFactory } from '@/javascript/test_support/factories.js'
import mockApi from '@/javascript/test_support/mock_api.js'

describe('TagGroupsLookup', () => {
  const goodTagGroupsFromDB = [
    {
      id: '1',
      type: 'tag_groups',
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
      tag_group_adapter_type: null,
    },
    {
      id: '2',
      type: 'tag_groups',
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
      tag_group_adapter_type: 'Chromium',
    },
  ]
  const goodTagGroupsList = {
    1: {
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
    2: {
      id: '2',
      uuid: 'tag-2-group-uuid',
      name: 'Tag Group 2',
      tags: [
        {
          index: 1,
          oligo: 'CCTTAAGG',
        },
        {
          index: 2,
          oligo: 'AATTCGCA',
        },
      ],
    },
  }
  const goodTagGroups = jsonCollectionFactory('tag_group', goodTagGroupsFromDB)
  const noTagGroups = jsonCollectionFactory('tag_group', [])

  const wrapperFactory = function (api = mockApi()) {
    return mount(TagGroupsLookup, {
      props: {
        api: api.devour,
        resourceName: 'tag_group',
      },
    })
  }

  it('is invalid if it can not find any tag groups', async () => {
    const api = mockApi()

    api.mockGet('tag_groups', { filter: {}, page: { number: 1, size: 150 } }, noTagGroups)

    const wrapper = wrapperFactory(api)

    expect(wrapper.vm.state).toEqual('searching')

    await flushPromises()

    expect(wrapper.vm.feedback).toEqual('No results retrieved')
    expect(wrapper.emitted()).toEqual({
      change: [[{ state: 'invalid', results: {} }]],
    })
  })

  it('is valid if it can find tag groups and sorts the tags in order of index', async () => {
    const api = mockApi()

    api.mockGet('tag_groups', { filter: {}, page: { number: 1, size: 150 } }, goodTagGroups)

    const wrapper = wrapperFactory(api)

    expect(wrapper.vm.state).toEqual('searching')

    await flushPromises()

    expect(wrapper.vm.state).toEqual('valid')

    const events = wrapper.emitted()

    expect(events.change.length).toEqual(1)
    expect(events.change[0][0].state).toEqual('valid')
    expect(events.change[0][0].results).toEqual(goodTagGroupsList)
  })
})
