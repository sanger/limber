import { shallowMount } from '@vue/test-utils'

import RequestTypeFilter from './RequestTypeFilter.vue'
import { requestFactory } from '@/javascript/test_support/factories.js'

describe('RequestTypeFilter', () => {
  const conversion = requestFactory({ uuid: 'conversion', request_type: { key: 'conversion_key' } })
  const multiplexing = requestFactory({ uuid: 'multiplexing', request_type: { key: 'multiplexing_key' } })
  const withoutType = requestFactory({ uuid: 'without-type' })

  const wrapperFactory = (requestsWithPlates) =>
    shallowMount(RequestTypeFilter, {
      props: { requestsWithPlates, requestTypeKeys: ['conversion_key'] },
    })

  it('keeps only the requests of the given request types', () => {
    const wrapper = wrapperFactory([{ request: conversion }, { request: multiplexing }, { request: withoutType }])

    expect(wrapper.vm.requestsWithPlatesFiltered).toEqual([{ request: conversion }])
  })

  it('emits the filtered requests when the requests change', async () => {
    const wrapper = wrapperFactory([])

    await wrapper.setProps({ requestsWithPlates: [{ request: conversion }, { request: multiplexing }] })

    expect(wrapper.emitted().change).toEqual([[[{ request: conversion }]]])
  })
})
