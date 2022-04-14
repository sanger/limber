// // Import the component being tested
import { shallowMount } from '@vue/test-utils'
import MultiStampTubes from './MultiStampTubes.vue'
import localVue from 'test_support/base_vue.js'
import { tubeFactory } from 'test_support/factories'
import flushPromises from 'flush-promises'

import MockAdapter from 'axios-mock-adapter'

const mockLocation = {}

describe('MultiStampTubes', () => {
  const wrapperFactory = function (options = {}) {
    // Not ideal using mount here, but having massive trouble
    // triggering change events on unmounted components
    return shallowMount(MultiStampTubes, {
      propsData: {
        targetRows: '8',
        targetColumns: '12',
        sourceTubes: '4',
        purposeUuid: 'test',
        requestsFilter: 'null',
        targetUrl: 'example/example',
        locationObj: mockLocation,
        transfersLayout: 'sequentialtube',
        transfersCreator: 'multi-stamp-tubes',
        allowTubeDuplicates: 'false',
        ...options,
      },
      localVue,
    })
  }

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

    expect(wrapper.find('b-button-stub').element.getAttribute('disabled')).toEqual('true')
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
    const validator = wrapper.vm.scanValidation[0]
    const validations = validator(tube1.labware)

    expect(validations.valid).toEqual(false)
  })

  it('is valid when we scan duplicate tubes and this is allowed', () => {
    const wrapper = wrapperFactory({ allowTubeDuplicates: 'true' })

    const tube1 = {
      state: 'valid',
      labware: tubeFactory({ uuid: 'tube-uuid-1' }),
    }

    wrapper.vm.updateTube(1, tube1)
    wrapper.vm.updateTube(2, tube1)
    const validator = wrapper.vm.scanValidation[0]
    const validations = validator(tube1.labware)

    expect(validations.valid).toEqual(true)
  })

  it('sends a post request when the button is clicked', async () => {
    let mock = new MockAdapter(localVue.prototype.$axios)

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
    mock.onPost().reply((config) => {
      expect(config.url).toEqual('example/example')
      expect(config.data).toEqual(JSON.stringify(expectedPayload))
      return [201, { redirect: 'http://wwww.example.com', message: 'Creating...' }]
    })

    // Ideally we'd emit the event from the button component, but I'm having difficulty.
    wrapper.vm.createPlate()

    await flushPromises()

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

  it('passes on the layout', () => {
    const tube1 = {
      state: 'valid',
      labware: tubeFactory({ uuid: 'tube-uuid-1' }),
    }
    const tube2 = {
      state: 'valid',
      labware: tubeFactory({ uuid: 'tube-uuid-2' }),
    }
    const tube3 = {
      state: 'valid',
      labware: tubeFactory({ uuid: 'tube-uuid-3' }),
    }
    const tube4 = {
      state: 'valid',
      labware: tubeFactory({ uuid: 'tube-uuid-4' }),
    }
    const wrapper = wrapperFactory()
    wrapper.vm.updateTube(1, tube1)
    wrapper.vm.updateTube(2, tube2)
    wrapper.vm.updateTube(3, tube3)
    wrapper.vm.updateTube(4, tube4)

    expect(wrapper.vm.targetWells).toEqual({
      A1: { pool_index: 1 },
      B1: { pool_index: 2 },
      C1: { pool_index: 3 },
      D1: { pool_index: 4 },
    })
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
})
