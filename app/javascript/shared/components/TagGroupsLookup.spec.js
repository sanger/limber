// Import the component being tested
import { mount } from '@vue/test-utils'
import flushPromises from 'flush-promises'
import TagGroupsLookup from 'shared/components/TagGroupsLookup.vue'
import { jsonCollectionFactory } from 'test_support/factories'
import mockApi from 'test_support/mock_api'
import localVue from 'test_support/base_vue'

describe('TagGroupsLookup', () => {
  const goodTagGroups = jsonCollectionFactory('tag_groups', [{ id: '1', name: 'Tag Group 1', tags: [{ index: 1, oligo: 'CTAGCTAG' }, { index: 2, oligo: 'TTATACGA'}],
                                                             { id: '2', name: 'Tag Group 2', tags: [{ index: 1, oligo: 'CCTTAAGG' }, { index: 2, oligo: 'AATTCGCA'}]
                                                            }])
  const nullTagGroups = { data: [] }

  const wrapperFactory = function(api = mockApi()) {
    // Not ideal using mount here, but having massive trouble
    // triggering change events on unmounted components
    return mount(TagGroupsLookup, {
      propsData: {
        api: api.devour,
      },
      localVue
    })
  }

  it('is invalid if it can not find a plate with the specified uuid', async () => {
    const api = mockApi()

    api.mockGet('tag_groups', {
      filter: { uuid: assetUuid },
      fields: {}
    }, nullTagGroups)

    const wrapper = wrapperFactory(api)

    expect(wrapper.vm.state).toEqual('searching')

    await flushPromises()

    expect(wrapper.vm.invalidFeedback).toEqual('Asset undefined')
    expect(wrapper.emitted()).toEqual({
      change: [
        [{ state: 'searching', asset: null }],
        [{ state: 'invalid', asset: null }]
      ]
    })
  })

  it('is invalid if there are api troubles', async () => {
    const api = mockApi()

    api.mockFail('tag_groups', {
      include: '',
      filter: { uuid: assetUuid },
      fields: {}
    }, { 'errors': [{
      title: 'Not good',
      detail: 'Very not good',
      code: 500,
      status: 500
    }]})

    const wrapper = wrapperFactory(api)

    expect(wrapper.vm.state).toEqual('searching')

    await flushPromises()

    expect(wrapper.vm.invalidFeedback).toEqual('Unknown Api error')
    expect(wrapper.emitted()).toEqual({
      change: [
        [{ state: 'searching', asset: null }],
        [{ state: 'invalid', asset: null }]
      ]
    })
  })

  it('is valid if it can find a plate', async () => {
    const api = mockApi()

    api.mockGet('tag_groups',{
      include: '',
      filter: { uuid: assetUuid },
      fields: {}
    }, goodTagGroups)

    const wrapper = wrapperFactory(api)

    expect(wrapper.vm.state).toEqual('searching')

    await flushPromises()

    expect(wrapper.vm.state).toEqual('valid')

    const events = wrapper.emitted()

    expect(events.change.length).toEqual(2)
    expect(events.change[0]).toEqual([{ state: 'searching', asset: null }])
    expect(events.change[1][0].state).toEqual('valid')
    expect(events.change[1][0].asset.uuid).toEqual(assetUuid)
  })

})
