// Import the component being tested
import { mount } from '@vue/test-utils'
import flushPromises from 'flush-promises'
import AssetLookupByUuid from 'shared/components/AssetLookupByUuid.vue'
import { jsonCollectionFactory } from 'test_support/factories'
import mockApi from 'test_support/mock_api'
import localVue from 'test_support/base_vue'

describe('AssetLookupByUuid', () => {
  const assetUuid = 'afabla7e-9498-42d6-964e-50f61ded6d9a'
  const nullPlate = { data: [] }
  const goodPlate = jsonCollectionFactory('plate', [{ uuid: assetUuid }])
  const badPlate = jsonCollectionFactory('plate', [{ uuid: assetUuid , number_of_columns: 24, number_of_rows: 8 }])

  const wrapperFactoryPlate = function(api = mockApi()) {
    // Not ideal using mount here, but having massive trouble
    // triggering change events on unmounted components
    return mount(AssetLookupByUuid, {
      propsData: {
        api: api.devour,
        assetUuid: assetUuid,
        assetType: 'plate',
        includes: '',
        fields: {}
      },
      localVue
    })
  }

  it('is invalid if it can not find a plate', async () => {
    const api = mockApi()

    api.mockGet('plates', {
      include: '',
      filter: { uuid: assetUuid },
      fields: {}
    }, nullPlate)

    const wrapper = wrapperFactoryPlate(api)

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

    api.mockFail('plates', {
      include: '',
      filter: { uuid: assetUuid },
      fields: {}
    }, { 'errors': [{
      title: 'Not good',
      detail: 'Very not good',
      code: 500,
      status: 500
    }]})

    const wrapper = wrapperFactoryPlate(api)

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

    api.mockGet('plates',{
      include: '',
      filter: { uuid: assetUuid },
      fields: {}
    }, goodPlate)

    const wrapper = wrapperFactoryPlate(api)

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
