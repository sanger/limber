// Import the component being tested
import { mount } from '@vue/test-utils'
import flushPromises from 'flush-promises'
import PlateScan from 'shared/components/PlateScan.vue'

// create an extended `Vue` constructor
import localVue from '_test_/support/base_vue'

describe('PlateScan', () => {

  const nullPlate = { data: null }
  const goodPlate = { data: 'Plate' }

  const mockApiFactory = function(promise) {
    return {
      where(options) {
        this.filteredWith = options
        return this
      },
      includes(options) {
        this.included = options
        return this
      },
      select(options) {
        this.selected = options
        return this
      },
      first() {
        return this.promise
      },
      promise: promise,
      filteredWith: '',
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
        plateApi: mockApi,
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

    expect(api.filteredWith).toEqual({ barcode: 'not a barcode' })
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

    expect(api.filteredWith).toEqual({ barcode: 'not a barcode' })
    expect(api.selected).toEqual({plates: ['labware_barcode', 'uuid']})
    expect(api.included).toEqual({wells: ['requests_as_source',{aliquots: 'request'}]})
    expect(wrapper.find('.valid-feedback').text()).toEqual('Great!')
    expect(wrapper.emitted()).toEqual({
      change: [
        [{ state: 'searching', plate: null }],
        [{ state: 'valid', plate: 'Plate' }]
      ]
    })
  })

})
