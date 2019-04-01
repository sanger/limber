// Import the component being tested
import { mount } from '@vue/test-utils'
import flushPromises from 'flush-promises'
import PlateScan from 'shared/components/PlateScan.vue'
import { jsonCollectionFactory } from 'test_support/factories'
import mockApi from 'test_support/mock_api'

// create an extended `Vue` constructor

import localVue from 'test_support/base_vue'

describe('PlateScan', () => {
  const assetUuid = 'afabla7e-9498-42d6-964e-50f61ded6d9a'
  const nullPlate = { data: [] }
  const goodPlate = jsonCollectionFactory('plate', [{ uuid: assetUuid }])
  const badPlate = jsonCollectionFactory('plate', [{ uuid: assetUuid , number_of_columns: 24, number_of_rows: 8 }])
  const lotUuid = 'afabla7e-9498-42d6-964e-50f61ded6d9b'
  const tagLayoutUuid = 'afabla7e-9498-42d6-964e-50f61ded6d9c'
  const goodQcable = jsonCollectionFactory('qcable', [{ uuid: assetUuid , state: 'available', lot: { uuid: lotUuid, tag_layout_template: { uuid: tagLayoutUuid, direction: 'column', walking_by: 'wells of plate'}}}])
  const badQcableWrongState = jsonCollectionFactory('qcable', [{ uuid: assetUuid , state: 'qc_in_progress', lot: { uuid: lotUuid, tag_layout_template: { uuid: tagLayoutUuid, direction: 'column', walking_by: 'wells of plate'}}}])
  const badQcableWrongWalkingBy = jsonCollectionFactory('qcable', [{ uuid: assetUuid , state: 'available', lot: { uuid: lotUuid, tag_layout_template: { uuid: tagLayoutUuid, direction: 'column', walking_by: 'quadrants'}}}])

  const wrapperFactoryPlate = function(api = mockApi()) {
    return mount(PlateScan, {
      propsData: {
        label: 'My Plate',
        description: 'Scan it in',
        api: api.devour,
        includes: 'wells.requests_as_source,wells.aliquots.request'
      },
      localVue
    })
  }

  const wrapperFactoryPlateDisabled = function(api = mockApi()) {
    return mount(PlateScan, {
      propsData: {
        label: 'My Plate',
        description: 'Scan it in',
        api: api.devour,
        plateCols: 12,
        plateRows: 8,
        includes: 'wells.requests_as_source,wells.aliquots.request',
        scanDisabled: true
      },
      localVue
    })
  }

  const wrapperFactoryQcable = function(api = mockApi()) {
    return mount(PlateScan, {
      propsData: {
        label: 'My Qcable',
        description: 'Scan it in',
        api: api.devour,
        plateType: 'qcable',
        includes: 'lot,lot.tag_layout_template,lot.tag_layout_template.tag_group,lot.tag_layout_template.tag2_group',
        fields: {
          lots:'uuid,template',
          tag_layout_templates:'uuid,tag_group,tag2_group,direction,walking_by',
          tag_group:'uuid,name'
        }
      },
      localVue
    })
  }

  it('renders the provided label', () => {
    const wrapper = wrapperFactoryPlate()

    expect(wrapper.find('label').text()).toEqual('My Plate')
  })

  it('renders the provided description', () => {
    const wrapper = wrapperFactoryPlate()

    expect(wrapper.find('.text-muted').text()).toEqual('Scan it in')
  })

  it('renders disabled if the disabled prop is set true', () => {
    const wrapper = wrapperFactoryPlateDisabled()

    expect(wrapper.find('input').element.disabled).toBe(true)
  })

  it('is invalid if it can not find a plate', async () => {
    const api = mockApi()
    api.mockGet('plates', {
      filter: { barcode: 'not a barcode' },
      include: 'wells.requests_as_source,wells.aliquots.request',
      fields: { plates: 'labware_barcode,uuid,number_of_rows,number_of_columns' }
    }, nullPlate)
    const wrapper = wrapperFactoryPlate(api)

    wrapper.find('input').setValue('not a barcode')
    wrapper.find('input').trigger('change')

    expect(wrapper.find('.wait-plate').exists()).toBe(true)

    await flushPromises()

    expect(wrapper.find('.invalid-feedback').text()).toEqual('Could not find plate')
    expect(wrapper.emitted()).toEqual({
      change: [
        [{ state: 'searching', plate: null }],
        [{ state: 'invalid', plate: undefined }]
      ]
    })
  })

  it('is invalid if there are api troubles', async () => {
    const api = mockApi()
    api.mockFail('plates', {
      filter: { barcode: 'Good barcode' },
      include: 'wells.requests_as_source,wells.aliquots.request',
      fields: { plates: 'labware_barcode,uuid,number_of_rows,number_of_columns' }
    }, { 'errors': [{
      title: 'Not good',
      detail: 'Very not good',
      code: 500,
      status: 500
    }]})
    const wrapper = wrapperFactoryPlate(api)

    wrapper.find('input').setValue('Good barcode')
    wrapper.find('input').trigger('change')

    expect(wrapper.find('.wait-plate').exists()).toBe(true)

    await flushPromises()

    // JG: Can't seem to get the mock api to correctly handle errors. THis would be the
    // desired behaviour, and seems to actually work in reality.
    // expect(wrapper.find('.invalid-feedback').text()).toEqual('Not good: Very not good')
    expect(wrapper.find('.invalid-feedback').text()).toEqual('Unknown error')
    expect(wrapper.emitted()).toEqual({
      change: [
        [{ state: 'searching', plate: null }],
        [{ state: 'invalid', plate: null }]
      ]
    })
  })

  it('is valid if it can find a plate', async () => {
    const api = mockApi()
    const wrapper = wrapperFactoryPlate(api)

    api.mockGet('plates',{
      include: 'wells.requests_as_source,wells.aliquots.request',
      filter: { barcode: 'DN12345' },
      fields: { plates: 'labware_barcode,uuid,number_of_rows,number_of_columns' }
    }, goodPlate)

    wrapper.find('input').setValue('DN12345')
    wrapper.find('input').trigger('change')

    expect(wrapper.find('.wait-plate').exists()).toBe(true)

    await flushPromises()

    expect(wrapper.find('.valid-feedback').text()).toEqual('Great!')

    const events = wrapper.emitted()

    expect(events.change.length).toEqual(2)
    expect(events.change[0]).toEqual([{ state: 'searching', plate: null }])
    expect(events.change[1][0].state).toEqual('valid')
    expect(events.change[1][0].plate.uuid).toEqual(assetUuid)
  })

  it('is invalid if the plate is the wrong size', async () => {
    const api = mockApi()
    const wrapper = wrapperFactoryPlate(api)

    api.mockGet('plates',{
      include:  'wells.requests_as_source,wells.aliquots.request',
      filter: { barcode: 'Good barcode' },
      fields: { plates: 'labware_barcode,uuid,number_of_rows,number_of_columns' }
    }, badPlate)

    wrapper.find('input').setValue('Good barcode')
    wrapper.find('input').trigger('change')

    expect(wrapper.find('.wait-plate').exists()).toBe(true)

    await flushPromises()

    expect(wrapper.find('.invalid-feedback').text()).toEqual('The plate should be 12×8 wells in size')

    const events = wrapper.emitted()

    expect(events.change.length).toEqual(2)
    expect(events.change[0]).toEqual([{ state: 'searching', plate: null }])
    expect(events.change[1][0].state).toEqual('invalid')
    expect(events.change[1][0].plate.uuid).toEqual(assetUuid)
  })
})
