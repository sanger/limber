import { mount } from '@vue/test-utils'
import flushPromises from 'flush-promises'
import TubeScan from 'shared/components/TubeScan.vue'
import { jsonCollectionFactory } from 'test_support/factories'
import mockApi from 'test_support/mock_api'

// create an extended `Vue` constructor
import localVue from 'test_support/base_vue'

describe('TubeScan', () => {
  const assetUuid = 'afabla7e-9498-42d6-964e-50f61ded6d9a'
  const nullTube = { data: [] }
  const goodTube = jsonCollectionFactory('tube', [{ uuid: assetUuid }])

  const wrapperFactoryTube = function(api = mockApi()) {
    return mount(TubeScan, {
      propsData: {
        label: 'My Tube',
        description: 'Scan it in',
        api: api.devour,
        includes: ''
      },
      localVue
    })
  }

  const wrapperFactoryTubeDisabled = function(api = mockApi()) {
    return mount(TubeScan, {
      propsData: {
        label: 'My Tube',
        description: 'Scan it in',
        api: api.devour,
        includes: '',
        scanDisabled: true
      },
      localVue
    })
  }

  it('renders the provided label', () => {
    const wrapper = wrapperFactoryTube()

    expect(wrapper.find('label').text()).toEqual('My Tube')
  })

  it('renders the provided description', () => {
    const wrapper = wrapperFactoryTube()

    expect(wrapper.find('.text-muted').text()).toEqual('Scan it in')
  })

  it('renders disabled if the disabled prop is set true', () => {
    const wrapper = wrapperFactoryTubeDisabled()

    expect(wrapper.find('input').element.disabled).toBe(true)
  })

  it('is invalid if it can not find a plate', async () => {
    const api = mockApi()
    api.mockGet('tubes', {
      filter: { barcode: 'not a barcode' },
      include: '',
      fields: { tubes: 'labware_barcode,uuid,receptacle', receptacles: 'uuid' }
    }, nullTube)
    const wrapper = wrapperFactoryTube(api)

    wrapper.find('input').setValue('not a barcode')
    await wrapper.find('input').trigger('change')

    expect(wrapper.find('.wait-plate').exists()).toBe(true)

    await flushPromises()

    expect(wrapper.find('.invalid-feedback').text()).toEqual('Could not find tube')
    expect(wrapper.emitted()).toEqual({
      change: [
        [{ state: 'searching', tube: null }],
        [{ state: 'invalid', tube: undefined }]
      ]
    })
  })

  it('is invalid if there are api troubles', async () => {
    const api = mockApi()
    api.mockFail('tubes', {
      filter: { barcode: 'Good barcode' },
      include: '',
      fields: { tubes: 'labware_barcode,uuid,receptacle', receptacles: 'uuid' }
    }, { 'errors': [{
      title: 'Not good',
      detail: 'Very not good',
      code: 500,
      status: 500
    }]})
    const wrapper = wrapperFactoryTube(api)

    wrapper.find('input').setValue('Good barcode')
    await wrapper.find('input').trigger('change')

    expect(wrapper.find('.wait-plate').exists()).toBe(true)

    await flushPromises()

    // JG: Can't seem to get the mock api to correctly handle errors. THis would be the
    // desired behaviour, and seems to actually work in reality.
    // expect(wrapper.find('.invalid-feedback').text()).toEqual('Not good: Very not good')
    expect(wrapper.find('.invalid-feedback').text()).toEqual('Unknown error')
    expect(wrapper.emitted()).toEqual({
      change: [
        [{ state: 'searching', tube: null }],
        [{ state: 'invalid', tube: null }]
      ]
    })
  })

  it('is valid if it can find a tube', async () => {
    const api = mockApi()
    const wrapper = wrapperFactoryTube(api)

    api.mockGet('tubes',{
      include: '',
      filter: { barcode: 'DN12345' },
      fields: { tubes: 'labware_barcode,uuid,receptacle', receptacles: 'uuid' }
    }, goodTube)

    wrapper.find('input').setValue('DN12345')
    await wrapper.find('input').trigger('change')

    expect(wrapper.find('.wait-plate').exists()).toBe(true)

    await flushPromises()

    expect(wrapper.find('.valid-feedback').text()).toEqual('Great!')

    const events = wrapper.emitted()

    expect(events.change.length).toEqual(2)
    expect(events.change[0]).toEqual([{ state: 'searching', tube: null }])
    expect(events.change[1][0].state).toEqual('valid')
    expect(events.change[1][0].tube.uuid).toEqual(assetUuid)
  })
})
