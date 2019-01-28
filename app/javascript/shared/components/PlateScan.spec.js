// Import the component being tested
import { mount } from '@vue/test-utils'
import flushPromises from 'flush-promises'
import PlateScan from 'shared/components/PlateScan.vue'
import { plateFactory } from 'test_support/factories'

// create an extended `Vue` constructor

import localVue from 'test_support/base_vue'

describe('PlateScan', () => {
  const nullPlate = { data: [] }
  const goodPlate = { data: [plateFactory()] }
  const badPlate = { data: [plateFactory({ number_of_columns: 24, number_of_rows: 8})] }

  const mockApiFactory = function(promise) {
    return {
      findAll(resource, options) {
        this.whered = options.filter
        this.included = options.include
        this.selected = options.select
        return this.promise
      },
      promise: promise,
      whered: {},
      selected: [],
      included: []
    }
  }

  const wrapperFactory = function(mockApi) {
    // Not ideal using mount here, but having massive trouble
    // triggering change events on unmounted components
    return mount(PlateScan, {
      propsData: {
        label: 'My Plate',
        description: 'Scan it in',
        api: mockApi,
        plateCols: 12,
        plateRows: 8,
        includes: {wells: ['requests_as_source',{aliquots: 'request'}]}
      },
      localVue
    })
  }

  it('renders the provided label', () => {
    const api = mockApiFactory()
    const wrapper = wrapperFactory(api)

    expect(wrapper.find('label').text()).toEqual('My Plate')
  })

  it('renders the provided description', () => {
    const api = mockApiFactory()
    const wrapper = wrapperFactory(api)

    expect(wrapper.find('.text-muted').text()).toEqual('Scan it in')
  })

  it('is invalid if it can not find a plate', async () => {
    const api = mockApiFactory(Promise.resolve(nullPlate))
    const wrapper = wrapperFactory(api)

    wrapper.find('input').setValue('not a barcode')
    wrapper.find('input').trigger('change')

    expect(wrapper.find('.wait-plate').exists()).toBe(true)

    await flushPromises()

    expect(api.whered).toEqual({ barcode: 'not a barcode' })
    expect(wrapper.find('.invalid-feedback').text()).toEqual('Could not find plate')
    expect(wrapper.emitted()).toEqual({
      change: [
        [{ state: 'searching', plate: null }],
        [{ state: 'invalid', plate: null }]
      ]
    })
  })

  it('is invalid if there are api troubles', async () => {
    const api = mockApiFactory(Promise.reject({ message: 'Nope' }))
    const wrapper = wrapperFactory(api)

    wrapper.find('input').setValue('Good barcode')
    wrapper.find('input').trigger('change')

    expect(wrapper.find('.wait-plate').exists()).toBe(true)

    await flushPromises()

    expect(wrapper.find('.invalid-feedback').text()).toEqual('Nope')
    expect(wrapper.emitted()).toEqual({
      change: [
        [{ state: 'searching', plate: null }],
        [{ state: 'invalid', plate: null }]
      ]
    })
  })

  it('is valid if it can find a plate', async () => {
    const api = mockApiFactory(Promise.resolve(goodPlate))
    const wrapper = wrapperFactory(api)

    wrapper.find('input').setValue('not a barcode')
    wrapper.find('input').trigger('change')

    expect(wrapper.find('.wait-plate').exists()).toBe(true)

    await flushPromises()

    expect(api.whered).toEqual({ barcode: 'not a barcode' })
    expect(api.selected).toEqual({plates: ['labware_barcode', 'uuid', 'number_of_rows', 'number_of_columns']})
    expect(api.included).toEqual({wells: ['requests_as_source',{aliquots: 'request'}]})
    expect(wrapper.find('.valid-feedback').text()).toEqual('Great!')
    expect(wrapper.emitted()).toEqual({
      change: [
        [{ state: 'searching', plate: null }],
        [{ state: 'valid', plate: goodPlate.data[0] }]
      ]
    })
  })

  it('is invalid if the plate is the wrong size', async () => {
    const api = mockApiFactory(Promise.resolve(badPlate))
    const wrapper = wrapperFactory(api)

    wrapper.find('input').setValue('Good barcode')
    wrapper.find('input').trigger('change')

    expect(wrapper.find('.wait-plate').exists()).toBe(true)

    await flushPromises()

    expect(wrapper.find('.invalid-feedback').text()).toEqual('The plate should be 12×8 wells in size')
    expect(wrapper.emitted()).toEqual({
      change: [
        [{ state: 'searching', plate: null }],
        [{ state: 'invalid', plate: badPlate.data[0] }]
      ]
    })
  })

})
