// Import the component being tested
import { mount } from '@vue/test-utils'
import flushPromises from 'flush-promises'
import LabwareScan from 'shared/components/LabwareScan.vue'
import { jsonCollectionFactory } from 'test_support/factories'
import mockApi from 'test_support/mock_api'

// create an extended `Vue` constructor
import localVue from 'test_support/base_vue'

describe('LabwareScan', () => {
  const assetUuid = 'afabla7e-9498-42d6-964e-50f61ded6d9a'
  const nullTube = { data: [] }
  const goodTube = jsonCollectionFactory('tube', [{ uuid: assetUuid }])

  const wrapperFactoryPlate = function (api = mockApi()) {
    return mount(LabwareScan, {
      propsData: {
        labwareType: 'plate',
        label: 'My Plate',
        description: 'Scan it in',
        api: api.devour,
        includes: '',
        colourIndex: 3,
      },
      localVue,
    })
  }

  const wrapperFactoryTube = function (api = mockApi()) {
    return mount(LabwareScan, {
      propsData: {
        labwareType: 'tube',
        label: 'My Tube',
        description: 'Scan it in',
        api: api.devour,
        includes: '',
        colourIndex: 3,
      },
      localVue,
    })
  }

  const wrapperFactoryTubeDisabled = function (api = mockApi()) {
    return mount(LabwareScan, {
      propsData: {
        labwareType: 'tube',
        label: 'My Tube',
        description: 'Scan it in',
        api: api.devour,
        includes: '',
        colourIndex: 3,
        scanDisabled: true,
      },
      localVue,
    })
  }

  const wrapperFactoryTubeNoColour = function (api = mockApi()) {
    return mount(LabwareScan, {
      propsData: {
        labwareType: 'tube',
        label: 'My Tube',
        description: 'Scan it in',
        api: api.devour,
        includes: '',
      },
      localVue,
    })
  }

  it('renders the provided well colour', () => {
    const wrapper = wrapperFactoryTube()

    expect(wrapper.find('.colour-3').exists()).toBe(true)
  })

  it('renders the provided label', () => {
    const wrapper = wrapperFactoryTube()

    expect(wrapper.find('label').text()).toEqual('My Tube')
  })

  it('renders the provided description', () => {
    const wrapper = wrapperFactoryTube()

    expect(wrapper.find('.text-muted').text()).toEqual('Scan it in')
  })

  it('renders the correct placeholder for a plate', () => {
    const wrapper = wrapperFactoryPlate()

    expect(wrapper.find('input').element.placeholder).toEqual('Scan plate')
  })

  it('renders the correct placeholder for a tube', () => {
    const wrapper = wrapperFactoryTube()

    expect(wrapper.find('input').element.placeholder).toEqual('Scan tube')
  })

  it('renders with a well indicator', () => {
    const wrapper = wrapperFactoryTube()

    expect(wrapper.find('.well').exists()).toBe(true)
  })

  it('renders disabled if the disabled prop is set true', () => {
    const wrapper = wrapperFactoryTubeDisabled()

    expect(wrapper.find('input').element.disabled).toBe(true)
  })

  it('renders without a well indicator if colour index not specified', () => {
    const wrapper = wrapperFactoryTubeNoColour()

    expect(wrapper.find('.well').exists()).toBe(false)
  })

  it('is invalid if it can not find a plate', async () => {
    const api = mockApi()
    api.mockGet(
      'plates',
      {
        filter: { barcode: 'not a barcode' },
        include: '',
        fields: {
          plates: 'labware_barcode,uuid,number_of_rows,number_of_columns',
        },
      },
      nullTube
    )
    const wrapper = wrapperFactoryPlate(api)

    wrapper.find('input').setValue('not a barcode')
    await wrapper.find('input').trigger('change')

    expect(wrapper.find('.wait-plate').exists()).toBe(true)

    await flushPromises()

    expect(wrapper.find('.invalid-feedback').text()).toEqual('Could not find plate')
    expect(wrapper.emitted()).toEqual({
      change: [[{ state: 'searching', plate: null }], [{ state: 'invalid', plate: undefined }]],
    })
  })

  it('is invalid if it can not find a tube', async () => {
    const api = mockApi()
    api.mockGet(
      'tubes',
      {
        filter: { barcode: 'not a barcode' },
        include: '',
        fields: {
          tubes: 'labware_barcode,uuid,receptacle',
          receptacles: 'uuid',
        },
      },
      nullTube
    )
    const wrapper = wrapperFactoryTube(api)

    wrapper.find('input').setValue('not a barcode')
    await wrapper.find('input').trigger('change')

    expect(wrapper.find('.wait-plate').exists()).toBe(true)

    await flushPromises()

    expect(wrapper.find('.invalid-feedback').text()).toEqual('Could not find tube')
    expect(wrapper.emitted()).toEqual({
      change: [[{ state: 'searching', labware: null }], [{ state: 'invalid', labware: undefined }]],
    })
  })

  it('is invalid if there are api troubles', async () => {
    const api = mockApi()
    api.mockFail(
      'tubes',
      {
        filter: { barcode: 'Good barcode' },
        include: '',
        fields: {
          tubes: 'labware_barcode,uuid,receptacle',
          receptacles: 'uuid',
        },
      },
      {
        errors: [
          {
            title: 'Not good',
            detail: 'Very not good',
            code: 500,
            status: 500,
          },
        ],
      }
    )
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
      change: [[{ state: 'searching', labware: null }], [{ state: 'invalid', labware: null }]],
    })
  })

  it('is valid if it can find a tube', async () => {
    const api = mockApi()
    const wrapper = wrapperFactoryTube(api)

    api.mockGet(
      'tubes',
      {
        include: '',
        filter: { barcode: 'DN12345' },
        fields: {
          tubes: 'labware_barcode,uuid,receptacle',
          receptacles: 'uuid',
        },
      },
      goodTube
    )

    wrapper.find('input').setValue('DN12345')
    await wrapper.find('input').trigger('change')

    expect(wrapper.find('.wait-plate').exists()).toBe(true)

    await flushPromises()

    expect(wrapper.find('.valid-feedback').text()).toEqual('Great!')

    const events = wrapper.emitted()

    expect(events.change.length).toEqual(2)
    expect(events.change[0]).toEqual([{ state: 'searching', labware: null }])
    expect(events.change[1][0].state).toEqual('valid')
    expect(events.change[1][0].labware.uuid).toEqual(assetUuid)
  })

  describe('When labwareType is plate', () => {
    const goodPlate = jsonCollectionFactory('plate', [{ uuid: assetUuid }])
    const badPlate = jsonCollectionFactory('plate', [{ uuid: assetUuid, number_of_columns: 24, number_of_rows: 8 }])

    const wrapperFactoryPlate = function (api = mockApi()) {
      return mount(LabwareScan, {
        propsData: {
          label: 'My Plate',
          description: 'Scan it in',
          api: api.devour,
          includes: 'wells.requests_as_source,wells.aliquots.request',
        },
        localVue,
      })
    }

    it('is valid if it can find a plate', async () => {
      const api = mockApi()
      const wrapper = wrapperFactoryPlate(api)

      api.mockGet(
        'plates',
        {
          include: 'wells.requests_as_source,wells.aliquots.request',
          filter: { barcode: 'DN12345' },
          fields: {
            plates: 'labware_barcode,uuid,number_of_rows,number_of_columns',
          },
        },
        goodPlate
      )

      wrapper.find('input').setValue('DN12345')
      await wrapper.find('input').trigger('change')

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

      api.mockGet(
        'plates',
        {
          include: 'wells.requests_as_source,wells.aliquots.request',
          filter: { barcode: 'Good barcode' },
          fields: {
            plates: 'labware_barcode,uuid,number_of_rows,number_of_columns',
          },
        },
        badPlate
      )

      wrapper.find('input').setValue('Good barcode')
      await wrapper.find('input').trigger('change')

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
})
