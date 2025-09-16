import { mount } from '@vue/test-utils'
import { flushPromises } from '@vue/test-utils'
import AssetLookupByUuid from '@/javascript/shared/components/AssetLookupByUuid.vue'
import { jsonCollectionFactory } from '@/javascript/test_support/factories.js'
import mockApi from '@/javascript/test_support/mock_api.js'

describe('AssetLookupByUuid', () => {
  const assetUuid = 'afabla7e-9498-42d6-964e-50f61ded6d9a'
  const goodPlate = jsonCollectionFactory('plate', [{ uuid: assetUuid }])

  const wrapperFactoryPlate = function (api = mockApi()) {
    // Not ideal using mount here, but having trouble
    // triggering change events on unmounted components
    return mount(AssetLookupByUuid, {
      props: {
        api: api.devour,
        resourceName: 'plate',
        includes: '',
        fields: {},
        filter: { uuid: assetUuid },
      },
    })
  }

  it('is invalid if it can not find a plate with the specified uuid', async () => {
    const api = mockApi()

    api.mockGet(
      'plates',
      {
        include: '',
        filter: { uuid: assetUuid },
        fields: {},
      },
      { data: [] }, // no plates found
    )

    const wrapper = wrapperFactoryPlate(api)

    expect(wrapper.vm.state).toEqual('searching')

    await flushPromises()

    expect(wrapper.vm.feedback).toEqual('No results retrieved')
    expect(wrapper.emitted()).toEqual({
      change: [[{ state: 'invalid', results: null }]],
    })
  })

  it('is valid if it can find a plate', async () => {
    const api = mockApi()

    api.mockGet(
      'plates',
      {
        include: '',
        filter: { uuid: assetUuid },
        fields: {},
      },
      goodPlate,
    )

    const wrapper = wrapperFactoryPlate(api)

    expect(wrapper.vm.state).toEqual('searching')

    await flushPromises()

    expect(wrapper.vm.state).toEqual('valid')

    const events = wrapper.emitted()

    expect(events.change.length).toEqual(1)
    expect(events.change[0][0].state).toEqual('valid')
    expect(events.change[0][0].results.uuid).toEqual(assetUuid)
  })
})
