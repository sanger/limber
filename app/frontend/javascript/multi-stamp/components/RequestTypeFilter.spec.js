import { shallowMount } from '@vue/test-utils'

import RequestTypeFilter from './RequestTypeFilter.vue'
import { requestFactory } from '@/javascript/test_support/factories.js'

describe('RequestTypeFilter', () => {
  const aggregation = requestFactory({ uuid: 'aggregation', request_type: { key: 'aggregation_key' } })
  const multiplexing = requestFactory({ uuid: 'multiplexing', request_type: { key: 'multiplexing_key' } })
  const withoutType = requestFactory({ uuid: 'without-type' })

  const wrapperFactory = (requestsWithPlates) =>
    shallowMount(RequestTypeFilter, {
      props: { requestsWithPlates, requestTypeKeys: ['aggregation_key'] },
    })

  it('keeps only the requests of the given request types', () => {
    const wrapper = wrapperFactory([{ request: aggregation }, { request: multiplexing }, { request: withoutType }])

    expect(wrapper.vm.requestsWithPlatesFiltered).toEqual([{ request: aggregation }])
  })

  it('emits the filtered requests when the requests change', async () => {
    const wrapper = wrapperFactory([])

    await wrapper.setProps({ requestsWithPlates: [{ request: aggregation }, { request: multiplexing }] })

    expect(wrapper.emitted().change).toEqual([[[{ request: aggregation }]]])
  })
})
