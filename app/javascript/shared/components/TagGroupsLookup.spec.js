// Import the component being tested
import { mount } from '@vue/test-utils'
import flushPromises from 'flush-promises'
import TagGroupsLookup from 'shared/components/TagGroupsLookup.vue'
import { jsonCollectionFactory } from 'test_support/factories'
import mockApi from 'test_support/mock_api'
import localVue from 'test_support/base_vue'

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
          oligo: 'CTAGCTAG'
        },
        {
          index: 2,
          oligo: 'TTATACGA'
        }
      ]
    },{
      id: '2',
      type: 'tag_groups',
      uuid: 'tag-2-group-uuid',
      name: 'Tag Group 2',
      tags: [
        {
          index: 2,
          oligo: 'AATTCGCA'
        },
        {
          index: 1,
          oligo: 'CCTTAAGG'
        }
      ]
    }
  ]
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
  const goodTagGroups = jsonCollectionFactory('tag_group', goodTagGroupsFromDB)
  const noTagGroups = jsonCollectionFactory('tag_group', [])

  const wrapperFactory = function(api = mockApi()) {
    return mount(TagGroupsLookup, {
      propsData: {
        api: api.devour,
      },
      localVue
    })
  }

  it('is invalid if it can not find any tag groups', async () => {
    const api = mockApi()

    api.mockGet('tag_groups', {"page":{"number":1,"size":150}}, noTagGroups)

    const wrapper = wrapperFactory(api)

    expect(wrapper.vm.state).toEqual('searching')

    await flushPromises()

    expect(wrapper.vm.invalidFeedback).toEqual('No tag groups found')
    expect(wrapper.emitted()).toEqual({
      change: [
        [{ state: 'searching', tagGroupsList: null }],
        [{ state: 'invalid', tagGroupsList: null }]
      ]
    })
  })

  it('is invalid if there are api troubles', async () => {
    const api = mockApi()

    api.mockFail('tag_groups', {"page":{"number":1,"size":150}}, {
      'errors': [{
        title: 'Not good',
        detail: 'Very not good',
        code: 500,
        status: 500
      }]
    })

    const wrapper = wrapperFactory(api)

    expect(wrapper.vm.state).toEqual('searching')

    await flushPromises()

    expect(wrapper.vm.invalidFeedback).toEqual('Unknown Api error')
    expect(wrapper.emitted()).toEqual({
      change: [
        [{ state: 'searching', tagGroupsList: null }],
        [{ state: 'invalid', tagGroupsList: null }]
      ]
    })
  })

  it('is valid if it can find tag groups and sorts the tags in order of index', async () => {
    const api = mockApi()

    api.mockGet('tag_groups', {"page":{"number":1,"size":150}}, goodTagGroups)

    const wrapper = wrapperFactory(api)

    expect(wrapper.vm.state).toEqual('searching')

    await flushPromises()

    expect(wrapper.vm.state).toEqual('valid')

    const events = wrapper.emitted()

    expect(events.change.length).toEqual(2)
    expect(events.change[0]).toEqual([{ state: 'searching', tagGroupsList: null }])
    expect(events.change[1][0].state).toEqual('valid')
    expect(events.change[1][0].tagGroupsList).toEqual(goodTagGroupsList)
  })

})
