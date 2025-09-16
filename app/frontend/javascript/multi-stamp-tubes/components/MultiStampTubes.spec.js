// // Import the component being tested
import { mount } from '@vue/test-utils'
import { flushPromises } from '@vue/test-utils'
import { aggregate } from '@/javascript/shared/components/scanValidators.js'
import { tubeFactory } from '@/javascript/test_support/factories.js'
import MultiStampTubes from './MultiStampTubes.vue'

const mockLocation = {}

describe('MultiStampTubes', () => {
  const wrapperFactory = function (options = {}) {
    // Not ideal using mount here, but having massive trouble
    // triggering change events on unmounted components
    return mount(MultiStampTubes, {
      props: {
        parentPurposeName: 'parent',
        purposeName: 'purpose',
        purposeUuid: 'test',
        targetRows: '8',
        targetColumns: '12',
        sourceTubes: '4',
        requestsFilter: 'null',
        targetUrl: 'example/example',
        locationObj: mockLocation,
        transfersLayout: 'sequentialtube',
        transfersCreator: 'multi-stamp-tubes',
        allowTubeDuplicates: 'false',
        requireTubePassed: 'false',
        acceptablePurposes: '[]',
        ...options,
      },
      global: {
        stubs: {
          LbPlate: true,
        },
      },
    })
  }

  it('renders the header', () => {
    const wrapper = wrapperFactory()

    expect(wrapper.findComponent({ name: 'b-card' }).vm.header).toEqual('Sample Arraying: parent → purpose')
  })

  it('disables creation if there are no tubes', () => {
    const wrapper = wrapperFactory()

    expect(wrapper.vm.valid).toEqual(false)
  })

  it('enables creation when there are all valid tubes', () => {
    const wrapper = wrapperFactory()
    const tube1 = {
      state: 'valid',
      labware: tubeFactory({ uuid: 'tube-uuid-1' }),
    }
    const tube2 = {
      state: 'valid',
      labware: tubeFactory({ uuid: 'tube-uuid-2' }),
    }

    wrapper.vm.updateTube(1, tube1)
    wrapper.vm.updateTube(2, tube2)

    wrapper.setData({
      transfersCreatorObj: { isValid: true, extraParams: (_) => {} },
    })

    expect(wrapper.vm.valid).toEqual(true)
  })

  it('disables creation when there are no possible transfers', () => {
    const wrapper = wrapperFactory()

    wrapper.setData({ tubes: [] })

    expect(wrapper.findComponent({ name: 'b-button' }).vm.disabled).toEqual(true)
  })

  it('disables creation when there are some invalid tubes', () => {
    const wrapper = wrapperFactory()
    const tube1 = {
      state: 'valid',
      labware: tubeFactory({ uuid: 'tube-uuid-1' }),
    }
    const tube2 = {
      state: 'invalid',
      labware: tubeFactory({ uuid: 'tube-uuid-2' }),
    }
    wrapper.vm.updateTube(1, tube1)
    wrapper.vm.updateTube(2, tube2)

    expect(wrapper.vm.valid).toEqual(false)
  })

  it('is not valid when we scan duplicate tubes', async () => {
    const wrapper = wrapperFactory()
    const tube1 = {
      state: 'valid',
      labware: tubeFactory({ uuid: 'tube-uuid-1' }),
    }

    wrapper.vm.updateTube(1, tube1)
    wrapper.vm.updateTube(2, tube1)

    const validationMessage = { message: 'Barcode has been scanned multiple times', valid: false }
    expect(wrapper.vm.scanValidation.length).toEqual(1)
    expect(aggregate(wrapper.vm.scanValidation, tube1.labware)).toEqual(validationMessage)
  })

  it('is valid when we scan pending tubes', async () => {
    const wrapper = wrapperFactory()
    const pendingTube = {
      state: 'valid',
      labware: tubeFactory({ state: 'pending' }),
    }

    wrapper.vm.updateTube(1, pendingTube)

    const validation = aggregate(wrapper.vm.scanValidation, pendingTube.labware)
    expect(validation).toHaveProperty('valid')
    expect(validation.valid).toEqual(true)
  })

  it('is valid when we scan passed tubes', async () => {
    const wrapper = wrapperFactory()
    const passedTube = {
      state: 'valid',
      labware: tubeFactory({ state: 'passed' }),
    }

    wrapper.vm.updateTube(1, passedTube)

    const validation = aggregate(wrapper.vm.scanValidation, passedTube.labware)
    expect(validation).toHaveProperty('valid')
    expect(validation.valid).toEqual(true)
  })

  it('sends a post request when the button is clicked', async () => {
    const tube = {
      state: 'valid',
      labware: tubeFactory({ uuid: 'tube-uuid' }),
    }
    const wrapper = wrapperFactory()
    wrapper.vm.updateTube(1, tube)

    wrapper.setData({
      transfersCreatorObj: { isValid: true, extraParams: (_) => {} },
    })
    const expectedPayload = {
      plate: {
        parent_uuid: 'tube-uuid',
        purpose_uuid: 'test',
        transfers: [
          {
            source_tube: 'tube-uuid',
            pool_index: 1,
            source_asset: 'receptacle-uuid',
            outer_request: null,
            new_target: { location: 'A1' },
          },
        ],
      },
    }

    mockLocation.href = null
    wrapper.vm.$axios = vi
      .fn()
      .mockResolvedValue({ data: { redirect: 'http://wwww.example.com', message: 'Creating...' } })

    // Ideally we'd emit the event from the button component, but I'm having difficulty.
    wrapper.vm.createPlate()

    await flushPromises()

    expect(wrapper.vm.$axios).toHaveBeenCalledWith({
      method: 'post',
      url: 'example/example',
      data: expectedPayload,
      headers: { 'X-Requested-With': 'XMLHttpRequest' },
    })
    expect(wrapper.vm.progressMessage).toEqual('Creating...')
    expect(mockLocation.href).toEqual('http://wwww.example.com')
  })

  it('calculates transfers for multiple tubes', () => {
    const tube1 = {
      state: 'valid',
      labware: tubeFactory({
        uuid: 'tube-uuid-1',
        receptacle: { uuid: 'receptacle-uuid-1' },
      }),
    }
    const tube2 = {
      state: 'valid',
      labware: tubeFactory({
        uuid: 'tube-uuid-2',
        receptacle: { uuid: 'receptacle-uuid-2' },
      }),
    }
    const tube3 = {
      state: 'valid',
      labware: tubeFactory({
        uuid: 'tube-uuid-3',
        receptacle: { uuid: 'receptacle-uuid-3' },
      }),
    }
    const tube4 = {
      state: 'valid',
      labware: tubeFactory({
        uuid: 'tube-uuid-4',
        receptacle: { uuid: 'receptacle-uuid-4' },
      }),
    }
    const wrapper = wrapperFactory()
    wrapper.vm.updateTube(1, tube1)
    wrapper.vm.updateTube(2, tube2)
    wrapper.vm.updateTube(3, tube3)
    wrapper.vm.updateTube(4, tube4)

    wrapper.setData({
      transfersCreatorObj: { isValid: true, extraParams: (_) => {} },
    })

    expect(wrapper.vm.apiTransfers()).toEqual([
      {
        source_tube: 'tube-uuid-1',
        pool_index: 1,
        source_asset: 'receptacle-uuid-1',
        outer_request: null,
        new_target: { location: 'A1' },
      },
      {
        source_tube: 'tube-uuid-2',
        pool_index: 2,
        source_asset: 'receptacle-uuid-2',
        outer_request: null,
        new_target: { location: 'B1' },
      },
      {
        source_tube: 'tube-uuid-3',
        pool_index: 3,
        source_asset: 'receptacle-uuid-3',
        outer_request: null,
        new_target: { location: 'C1' },
      },
      {
        source_tube: 'tube-uuid-4',
        pool_index: 4,
        source_asset: 'receptacle-uuid-4',
        outer_request: null,
        new_target: { location: 'D1' },
      },
    ])
  })

  it('passes on the layout, assigning colour by machine barcode', () => {
    const tube1 = {
      state: 'valid',
      labware: tubeFactory({ uuid: 'tube-uuid-1', labware_barcode: { machine_barcode: 'barcode-1' } }),
    }
    const tube2 = {
      state: 'valid',
      labware: tubeFactory({ uuid: 'tube-uuid-2', labware_barcode: { machine_barcode: 'barcode-2' } }),
    }
    const tube3 = {
      state: 'valid',
      labware: tubeFactory({ uuid: 'tube-uuid-3', labware_barcode: { machine_barcode: 'barcode-2' } }),
    }
    const tube4 = {
      state: 'valid',
      labware: tubeFactory({ uuid: 'tube-uuid-4', labware_barcode: { machine_barcode: 'barcode-4' } }),
    }
    const wrapper = wrapperFactory()
    wrapper.vm.updateTube(1, tube1)
    wrapper.vm.updateTube(2, tube2)
    wrapper.vm.updateTube(3, tube3)
    wrapper.vm.updateTube(4, tube4)

    expect(wrapper.vm.targetWells).toEqual({
      A1: { colour_index: 1 },
      B1: { colour_index: 2 },
      C1: { colour_index: 2 },
      D1: { colour_index: 3 },
    })
  })

  it('recalculates the colour index when tubes are updated', () => {
    const noTube = { state: 'empty', labware: null }
    const tube1 = {
      state: 'valid',
      labware: tubeFactory({ uuid: 'tube-uuid-1', labware_barcode: { machine_barcode: 'barcode-1' } }),
    }
    const tube2 = {
      state: 'valid',
      labware: tubeFactory({ uuid: 'tube-uuid-2', labware_barcode: { machine_barcode: 'barcode-2' } }),
    }
    const wrapper = wrapperFactory()

    // add two different tubes
    wrapper.vm.updateTube(1, tube1)
    wrapper.vm.updateTube(2, tube2)
    expect(wrapper.vm.targetWells).toEqual({
      A1: { colour_index: 1 },
      B1: { colour_index: 2 },
    })

    // remove the first tube
    wrapper.vm.updateTube(1, noTube)
    expect(wrapper.vm.targetWells).toEqual({
      B1: { colour_index: 1 },
    })

    // add the second tube again, but in the first position
    wrapper.vm.updateTube(1, tube2)
    expect(wrapper.vm.targetWells).toEqual({
      A1: { colour_index: 1 },
      B1: { colour_index: 1 },
    })
  })

  it('renders the tube colours based on tube state', () => {
    const wrapper = wrapperFactory()

    const emptyTube = {
      state: 'empty',
      labware: null,
    }
    const notFoundTube = {
      state: 'invalid',
      labware: undefined,
    }
    const unknownTube = {
      state: 'valid',
      labware: tubeFactory({ uuid: 't-unknown', labware_barcode: { machine_barcode: 'UNKNOWN' }, state: 'unknown' }),
    }
    const pendingTube = {
      state: 'valid',
      labware: tubeFactory({ uuid: 't-pending', labware_barcode: { machine_barcode: 'PENDING' }, state: 'pending' }),
    }
    const passedTube = {
      state: 'valid',
      labware: tubeFactory({ uuid: 't-passed', labware_barcode: { machine_barcode: 'PASSED' }, state: 'passed' }),
    }

    wrapper.vm.updateTube(1, emptyTube)
    wrapper.vm.updateTube(2, notFoundTube)
    wrapper.vm.updateTube(3, unknownTube)
    wrapper.vm.updateTube(4, pendingTube)
    wrapper.vm.updateTube(5, passedTube)

    // shows only the (valid) tubes that are passed to the plate
    expect(wrapper.vm.targetWells).toEqual({
      C1: { colour_index: 1 },
      D1: { colour_index: 2 },
      E1: { colour_index: 3 },
    })

    // shows only the (valid) tubes that are passed to labware-scan
    expect(wrapper.vm.tubes.length).toEqual(5)
    let colourIndices = []
    for (let i = 0; i < 5; i++) {
      let result = wrapper.vm.colourIndex(i)
      colourIndices.push(result)
    }

    expect(colourIndices).toEqual([-1, -1, 1, 2, 3])

    // shows all the tubes (valid and invalid) that are passed to tube-array-summary
    // no colour index is assigned to tubes at this stage and all the tubes are passed
    // as-is to the tube-array-summary component where the colour index is assigned
  })

  it('does not display an alert if no invalid transfers are present', () => {
    const tube1 = {
      state: 'valid',
      labware: tubeFactory({ uuid: 'tube-1-uuid' }),
    }
    const wrapper = wrapperFactory()
    wrapper.vm.updateTube(1, tube1)

    expect(wrapper.vm.transfersError).toEqual('')
  })

  describe('when tubes are required to be in passed state', () => {
    it('is not valid when we scan duplicate tubes', async () => {
      const wrapper = wrapperFactory({ requireTubePassed: 'true' })
      const tube1 = {
        state: 'valid',
        labware: tubeFactory({ uuid: 'tube-uuid-1' }),
      }

      wrapper.vm.updateTube(1, tube1)
      wrapper.vm.updateTube(2, tube1)

      const validationMessage = { message: 'Barcode has been scanned multiple times', valid: false }
      expect(wrapper.vm.scanValidation.length).toEqual(2)
      expect(aggregate(wrapper.vm.scanValidation, tube1.labware)).toEqual(validationMessage)
    })

    it('is not valid when we scan pending tubes', async () => {
      const wrapper = wrapperFactory({ requireTubePassed: 'true' })
      const pendingTube = {
        state: 'valid',
        labware: tubeFactory({ state: 'pending' }),
      }

      wrapper.vm.updateTube(1, pendingTube)

      const validation = aggregate(wrapper.vm.scanValidation, pendingTube.labware)
      expect(validation).toHaveProperty('message')
      expect(validation.message).toContain('Tube (state: pending) must have a state of: ')
      expect(validation).toHaveProperty('valid')
      expect(validation.valid).toEqual(false)
    })

    it('is valid when we scan passed tubes', async () => {
      const wrapper = wrapperFactory({ requireTubePassed: 'true' })
      const passedTube = {
        state: 'valid',
        labware: tubeFactory({ state: 'passed' }),
      }

      wrapper.vm.updateTube(1, passedTube)

      const validation = aggregate(wrapper.vm.scanValidation, passedTube.labware)
      expect(validation).toHaveProperty('valid')
      expect(validation.valid).toEqual(true)
    })
  })

  describe('when tube duplicates are allowed', () => {
    it('is valid when we scan duplicate tubes and this is allowed', () => {
      const wrapper = wrapperFactory({ allowTubeDuplicates: 'true' })

      const tube1 = {
        state: 'valid',
        labware: tubeFactory({ uuid: 'tube-uuid-1' }),
      }

      wrapper.vm.updateTube(1, tube1)
      wrapper.vm.updateTube(2, tube1)

      const validationMessage = { valid: true }
      expect(aggregate(wrapper.vm.scanValidation, tube1.labware)).toEqual(validationMessage)
    })

    it('is valid when we scan pending tubes', async () => {
      const wrapper = wrapperFactory({ allowTubeDuplicates: 'true' })
      const pendingTube = {
        state: 'valid',
        labware: tubeFactory({ state: 'pending' }),
      }

      wrapper.vm.updateTube(1, pendingTube)

      const validation = aggregate(wrapper.vm.scanValidation, pendingTube.labware)
      expect(validation).toHaveProperty('valid')
      expect(validation.valid).toEqual(true)
    })

    it('is valid when we scan passed tubes', async () => {
      const wrapper = wrapperFactory({ allowTubeDuplicates: 'true' })
      const passedTube = {
        state: 'valid',
        labware: tubeFactory({ state: 'passed' }),
      }

      wrapper.vm.updateTube(1, passedTube)

      const validation = aggregate(wrapper.vm.scanValidation, passedTube.labware)
      expect(validation).toHaveProperty('valid')
      expect(validation.valid).toEqual(true)
    })
  })

  describe('when tube duplicates are allowed and when tubes are required to be in passed state', () => {
    it('is valid when we scan duplicate tubes and this is allowed', () => {
      const wrapper = wrapperFactory({ allowTubeDuplicates: 'true', requireTubePassed: 'true' })

      const tube1 = {
        state: 'valid',
        labware: tubeFactory({ uuid: 'tube-uuid-1' }),
      }

      wrapper.vm.updateTube(1, tube1)
      wrapper.vm.updateTube(2, tube1)

      const validationMessage = { valid: true }
      expect(aggregate(wrapper.vm.scanValidation, tube1.labware)).toEqual(validationMessage)
    })

    it('is not valid when we scan pending tubes', async () => {
      const wrapper = wrapperFactory({ allowTubeDuplicates: 'true', requireTubePassed: 'true' })
      const pendingTube = {
        state: 'valid',
        labware: tubeFactory({ state: 'pending' }),
      }

      wrapper.vm.updateTube(1, pendingTube)

      const validation = aggregate(wrapper.vm.scanValidation, pendingTube.labware)
      expect(validation).toHaveProperty('message')
      expect(validation.message).toContain('Tube (state: pending) must have a state of: ')
      expect(validation).toHaveProperty('valid')
      expect(validation.valid).toEqual(false)
    })

    it('is valid when we scan passed tubes', async () => {
      const wrapper = wrapperFactory({ allowTubeDuplicates: 'true', requireTubePassed: 'true' })
      const passedTube = {
        state: 'valid',
        labware: tubeFactory({ state: 'passed' }),
      }

      wrapper.vm.updateTube(1, passedTube)

      const validation = aggregate(wrapper.vm.scanValidation, passedTube.labware)
      expect(validation).toHaveProperty('valid')
      expect(validation.valid).toEqual(true)
    })
  })

  describe('when tubes are required to be in the acceptablePurposes list', () => {
    it('is not valid when we scan tubes with purposes not in the acceptablePurposes list', async () => {
      const wrapper = wrapperFactory({ acceptablePurposes: JSON.stringify(['A Purpose']) })
      const tube1 = {
        state: 'valid',
        labware: tubeFactory({ uuid: 'tube-uuid-1', purpose: { name: 'Another Purpose' } }),
      }

      wrapper.vm.updateTube(1, tube1)

      const validationMessage = {
        message: "Tube purpose 'Another Purpose' is not in the acceptable purpose list: A Purpose",
        valid: false,
      }
      expect(wrapper.vm.scanValidation.length).toEqual(2)
      expect(aggregate(wrapper.vm.scanValidation, tube1.labware)).toEqual(validationMessage)
    })

    it('is valid when we scan tubes with purposes in the acceptablePurposes list', async () => {
      const wrapper = wrapperFactory({ acceptablePurposes: JSON.stringify(['A Purpose']) })
      const tube1 = {
        state: 'valid',
        labware: tubeFactory({ uuid: 'tube-uuid-1', purpose: { name: 'A Purpose' } }),
      }

      wrapper.vm.updateTube(1, tube1)

      const validation = aggregate(wrapper.vm.scanValidation, tube1.labware)
      expect(validation).toHaveProperty('valid')
      expect(validation.valid).toEqual(true)
    })
  })
})
