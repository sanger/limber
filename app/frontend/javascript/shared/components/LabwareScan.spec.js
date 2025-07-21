// Note: strictly speaking this is an integration test, not a unit test, as it includes mocks at the API level

// Import the component being tested
import { mount } from '@vue/test-utils'
import { flushPromises } from '@vue/test-utils'
import LabwareScan from '@/javascript/shared/components/LabwareScan.vue'
import { checkState } from '@/javascript/shared/components/tubeScanValidators.js'
import { jsonCollectionFactory } from '@/javascript/test_support/factories.js'
import mockApi from '@/javascript/test_support/mock_api.js'

describe('LabwareScan', () => {
  const wrapperFactoryPlate = function (api = mockApi()) {
    return mount(LabwareScan, {
      props: {
        labwareType: 'plate',
        label: 'My Plate',
        description: 'Scan it in',
        api: api.devour,
        includes: '',
        colourIndex: 3,
      },
    })
  }

  const wrapperFactoryTube = function (api = mockApi(), validators = undefined) {
    return mount(LabwareScan, {
      props: {
        labwareType: 'tube',
        label: 'My Tube',
        description: 'Scan it in',
        api: api.devour,
        includes: '',
        colourIndex: 3,
        validators: validators,
      },
    })
  }

  const wrapperFactoryTubeDisabled = function (api = mockApi()) {
    return mount(LabwareScan, {
      props: {
        labwareType: 'tube',
        label: 'My Tube',
        description: 'Scan it in',
        api: api.devour,
        includes: '',
        colourIndex: 3,
        scanDisabled: true,
      },
    })
  }

  const wrapperFactoryTubeNoColour = function (api = mockApi()) {
    return mount(LabwareScan, {
      props: {
        labwareType: 'tube',
        label: 'My Tube',
        description: 'Scan it in',
        api: api.devour,
        includes: '',
      },
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

    expect(wrapper.find('.text-body-secondary').text()).toEqual('Scan it in')
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

  describe('When labwareType is tube', () => {
    const goodTubeUuid = 'afabla7e-9498-42d6-964e-50f61ded6d9a'
    const pendingTubeUuid = '123e4567-e89b-12d3-a456-426614174000'
    const nullTube = { data: [] }
    const goodTube = jsonCollectionFactory('tube', [{ uuid: goodTubeUuid, state: 'passed' }])
    const pendingTube = jsonCollectionFactory('tube', [{ uuid: pendingTubeUuid, state: 'pending' }])

    it('is valid if it can find a tube', async () => {
      const api = mockApi()
      const wrapper = wrapperFactoryTube(api)

      api.mockGet(
        'tubes',
        {
          include: '',
          filter: { barcode: 'DN12345' },
          fields: {
            tubes: 'labware_barcode,uuid,receptacle,state,purpose',
            receptacles: 'uuid',
          },
        },
        goodTube,
      )

      wrapper.find('input').setValue('DN12345')
      await wrapper.find('input').trigger('change')

      expect(wrapper.find('.wait-labware').exists()).toBe(true)

      await flushPromises()

      expect(wrapper.find('.valid-feedback').text()).toEqual('Great!')

      const events = wrapper.emitted()

      expect(events.change.length).toEqual(2)
      expect(events.change[0]).toEqual([{ state: 'searching', labware: null }])
      expect(events.change[1][0].state).toEqual('valid')
      expect(events.change[1][0].labware.uuid).toEqual(goodTubeUuid)
    })

    it('is invalid if it can not find a tube', async () => {
      const api = mockApi()
      api.mockGet(
        'tubes',
        {
          filter: { barcode: 'not a barcode' },
          include: '',
          fields: {
            tubes: 'labware_barcode,uuid,receptacle,state,purpose',
            receptacles: 'uuid',
          },
        },
        nullTube,
      )
      const wrapper = wrapperFactoryTube(api)

      wrapper.find('input').setValue('not a barcode')
      await wrapper.find('input').trigger('change')

      expect(wrapper.find('.wait-labware').exists()).toBe(true)

      await flushPromises()

      expect(wrapper.find('.invalid-feedback').text()).toEqual('Could not find tube')
      expect(wrapper.emitted().change).toEqual([
        [{ state: 'searching', labware: null }],
        [{ state: 'invalid', labware: undefined }],
      ])
    })

    it('is invalid if the tube is in the pending state', async () => {
      const api = mockApi()
      const validators = [checkState(['passed'])]
      const wrapper = wrapperFactoryTube(api, validators)

      api.mockGet(
        'tubes',
        {
          include: '',
          filter: { barcode: 'Good barcode' },
          fields: {
            tubes: 'labware_barcode,uuid,receptacle,state,purpose',
            receptacles: 'uuid',
          },
        },
        pendingTube,
      )

      wrapper.find('input').setValue('Good barcode')
      await wrapper.find('input').trigger('change')

      expect(wrapper.find('.wait-labware').exists()).toBe(true)

      await flushPromises()

      expect(wrapper.find('.is-invalid').exists()).toBe(true)
      expect(wrapper.find('.invalid-feedback').text()).toEqual('Tube (state: pending) must have a state of: passed')

      const events = wrapper.emitted()

      expect(events.change.length).toEqual(2)
      expect(events.change[0]).toEqual([{ state: 'searching', labware: null }])
      expect(events.change[1][0].state).toEqual('invalid')
      expect(events.change[1][0].labware.uuid).toEqual(pendingTubeUuid)
    })

    it('is invalid if there are api troubles', async () => {
      // Devour automatically logs the error, which looks like:
      //   console.log
      //     devour error {
      //       error: {
      //         errors: [
      //           {
      //             title: 'Not good',
      //             detail: 'Very not good',
      //             code: 500,
      //             status: 500
      //           }
      //         ]
      //       }
      //     }
      // We suppress this error with the below spy.
      vi.spyOn(console, 'log').mockImplementation((log) => {
        if (log.includes('devour error')) return false
      })

      const api = mockApi()
      api.mockFail(
        'tubes',
        {
          filter: { barcode: 'Good barcode' },
          include: '',
          fields: {
            tubes: 'labware_barcode,uuid,receptacle,state,purpose',
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
        },
      )
      const wrapper = wrapperFactoryTube(api)

      wrapper.find('input').setValue('Good barcode')
      await wrapper.find('input').trigger('change')

      expect(wrapper.find('.wait-labware').exists()).toBe(true)

      await flushPromises()

      expect(wrapper.find('.invalid-feedback').text()).toEqual('Not good: Very not good')
      expect(wrapper.emitted().change).toEqual([
        [{ state: 'searching', labware: null }],
        [{ state: 'invalid', labware: null }],
      ])
    })
  })

  describe('When labwareType is plate', () => {
    const goodPlateUuid = '550e8400-e29b-41d4-a716-446655440000'
    const badPlateUuid = '550e8400-e29b-41d4-a716-446655440001'
    const nullPlate = { data: [] }
    const goodPlate = jsonCollectionFactory('plate', [{ uuid: goodPlateUuid }])
    const badPlate = jsonCollectionFactory('plate', [{ uuid: badPlateUuid, number_of_columns: 24, number_of_rows: 8 }])

    const wrapperFactoryPlate = function (api = mockApi()) {
      return mount(LabwareScan, {
        props: {
          label: 'My Plate',
          description: 'Scan it in',
          api: api.devour,
          includes: 'wells.requests_as_source,wells.aliquots.request',
        },
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
        goodPlate,
      )

      wrapper.find('input').setValue('DN12345')
      await wrapper.find('input').trigger('change')

      expect(wrapper.find('.wait-labware').exists()).toBe(true)

      await flushPromises()

      expect(wrapper.find('.valid-feedback').text()).toEqual('Great!')

      const events = wrapper.emitted()

      expect(events.change.length).toEqual(2)
      expect(events.change[0]).toEqual([{ state: 'searching', plate: null }])
      expect(events.change[1][0].state).toEqual('valid')
      expect(events.change[1][0].plate.uuid).toEqual(goodPlateUuid)
    })

    it('is invalid if it can not find a plate', async () => {
      const api = mockApi()
      api.mockGet(
        'plates',
        {
          filter: { barcode: 'not a barcode' },
          include: 'wells.requests_as_source,wells.aliquots.request',
          fields: {
            plates: 'labware_barcode,uuid,number_of_rows,number_of_columns',
          },
        },
        nullPlate,
      )
      const wrapper = wrapperFactoryPlate(api)

      wrapper.find('input').setValue('not a barcode')
      await wrapper.find('input').trigger('change')

      expect(wrapper.find('.wait-labware').exists()).toBe(true)

      await flushPromises()

      expect(wrapper.find('.invalid-feedback').text()).toEqual('Could not find plate')
      expect(wrapper.emitted().change).toEqual([
        [{ state: 'searching', plate: null }],
        [{ state: 'invalid', plate: undefined }],
      ])
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
        badPlate,
      )

      wrapper.find('input').setValue('Good barcode')
      await wrapper.find('input').trigger('change')

      expect(wrapper.find('.wait-labware').exists()).toBe(true)

      await flushPromises()

      expect(wrapper.find('.invalid-feedback').text()).toEqual('The plate should be 12×8 wells in size')

      const events = wrapper.emitted()

      expect(events.change.length).toEqual(2)
      expect(events.change[0]).toEqual([{ state: 'searching', plate: null }])
      expect(events.change[1][0].state).toEqual('invalid')
      expect(events.change[1][0].plate.uuid).toEqual(badPlateUuid)
    })

    it('is invalid if there are api troubles', async () => {
      // Devour automatically logs the error, which looks like:
      //   console.log
      //     devour error {
      //       error: {
      //         errors: [
      //           {
      //             title: 'Not good',
      //             detail: 'Very not good',
      //             code: 500,
      //             status: 500
      //           }
      //         ]
      //       }
      //     }
      // Please do not panic, but it would be nice to suppress _only this output_ this in the console
      const api = mockApi()
      api.mockFail(
        'plates',
        {
          filter: { barcode: 'Good barcode' },
          include: 'wells.requests_as_source,wells.aliquots.request',
          fields: {
            plates: 'labware_barcode,uuid,number_of_rows,number_of_columns',
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
        },
      )
      const wrapper = wrapperFactoryPlate(api)

      wrapper.find('input').setValue('Good barcode')
      await wrapper.find('input').trigger('change')

      expect(wrapper.find('.wait-labware').exists()).toBe(true)

      await flushPromises()

      expect(wrapper.find('.invalid-feedback').text()).toEqual('Not good: Very not good')
      expect(wrapper.emitted().change).toEqual([
        [{ state: 'searching', plate: null }],
        [{ state: 'invalid', plate: null }],
      ])
    })
  })
})
