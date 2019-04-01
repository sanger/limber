// // Import the component being tested
import { shallowMount } from '@vue/test-utils'
import MultiStamp from './MultiStamp.vue'
import localVue from 'test_support/base_vue.js'
import { plateFactory } from 'test_support/factories.js'
import flushPromises from 'flush-promises'

import MockAdapter from 'axios-mock-adapter'

const mockLocation = {}

describe('MultiStamp', () => {
  const wrapperFactory = function() {
    // Not ideal using mount here, but having massive trouble
    // triggering change events on unmounted components
    return shallowMount(MultiStamp, {
      propsData: {
        targetRows: '16',
        targetColumns: '24',
        sourcePlates: '4',
        purposeUuid: 'test',
        requestFilter: 'null',
        targetUrl: 'example/example',
        locationObj: mockLocation,
        transfersLayout: 'quadrant'
      },
      localVue
    })
  }

  it('disables creation if there are no plates', () => {
    const wrapper = wrapperFactory()

    expect(wrapper.vm.valid).toEqual(false)
  })

  it('enables creation when there are all valid plates', () => {
    const wrapper = wrapperFactory()
    const plate1 = { state: 'valid', plate: plateFactory({ uuid: 'plate-uuid-1', _filledWells: 4 }) }
    const plate2 = { state: 'valid', plate: plateFactory({ uuid: 'plate-uuid-2', _filledWells: 4 }) }
    wrapper.vm.updatePlate(1, plate1)
    wrapper.vm.updatePlate(2, plate2)

    wrapper.setData({ requestsWithPlatesFiltered: wrapper.vm.requestsWithPlates })

    expect(wrapper.vm.valid).toEqual(true)
  })

  it('disables creation when there are no possible transfers', () => {
    const wrapper = wrapperFactory()

    wrapper.setData({ requestsWithPlatesFiltered: [] })

    expect(wrapper.find('bbutton-stub').element.getAttribute('disabled')).toEqual('true')
  })

  it('disables creation when there are some invalid plates', () => {
    const wrapper = wrapperFactory()
    const plate1 = { state: 'valid', plate: plateFactory({ uuid: 'plate-uuid-1', _filledWells: 4 }) }
    const plate2 = { state: 'invalid', plate: plateFactory({ uuid: 'plate-uuid-2', _filledWells: 4 }) }
    wrapper.vm.updatePlate(1, plate1)
    wrapper.vm.updatePlate(2, plate2)

    wrapper.setData({ requestsWithPlatesFiltered: wrapper.vm.requestsWithPlates })

    expect(wrapper.vm.valid).toEqual(false)
  })

  it('sends a post request when the button is clicked', async () => {
    let mock = new MockAdapter(localVue.prototype.$axios)

    const plate = { state: 'valid', plate: plateFactory({ uuid: 'plate-uuid', _filledWells: 1 }) }
    const wrapper = wrapperFactory()
    wrapper.vm.updatePlate(1, plate)

    wrapper.setData({ requestsWithPlatesFiltered: wrapper.vm.requestsWithPlates })

    const expectedPayload = { plate: {
      parent_uuid: 'plate-uuid',
      purpose_uuid: 'test',
      transfers: [
        { source_plate: 'plate-uuid', pool_index: 1, source_asset: 'plate-uuid-well-0', outer_request: 'plate-uuid-well-0-source-request-0', new_target: { location: 'A1' } }
      ]
    }}

    mockLocation.href = null
    mock.onPost().reply((config) =>{

      expect(config.url).toEqual('example/example')
      expect(config.data).toEqual(JSON.stringify(expectedPayload))
      return [201, { redirect: 'http://wwww.example.com', message: 'Creating...' }]
    })

    // Ideally we'd emit the event from the button component, but I'm having difficulty.
    wrapper.vm.createPlate()

    await flushPromises()

    expect(mockLocation.href).toEqual('http://wwww.example.com')

  })

  it('calculates transfers', () => {
    const plate = { state: 'valid', plate: plateFactory({ uuid: 'plate-uuid', _filledWells: 4 }) }
    const wrapper = wrapperFactory()
    wrapper.vm.updatePlate(1, plate)

    wrapper.setData({ requestsWithPlatesFiltered: wrapper.vm.requestsWithPlates })

    expect(wrapper.vm.transfers.valid).toEqual([
      { source_plate: 'plate-uuid', pool_index: 1, source_asset: 'plate-uuid-well-0', outer_request: 'plate-uuid-well-0-source-request-0', new_target: { location: 'A1' } },
      { source_plate: 'plate-uuid', pool_index: 1, source_asset: 'plate-uuid-well-1', outer_request: 'plate-uuid-well-1-source-request-0', new_target: { location: 'C1' } },
      { source_plate: 'plate-uuid', pool_index: 1, source_asset: 'plate-uuid-well-2', outer_request: 'plate-uuid-well-2-source-request-0', new_target: { location: 'E1' } },
      { source_plate: 'plate-uuid', pool_index: 1, source_asset: 'plate-uuid-well-3', outer_request: 'plate-uuid-well-3-source-request-0', new_target: { location: 'G1' } }
    ])
  })

  it('handles multiple plates', () => {
    const plate1 = { state: 'valid', plate: plateFactory({ uuid: 'plate-1-uuid', _filledWells: 4 }) }
    const plate2 = { state: 'valid', plate: plateFactory({ uuid: 'plate-2-uuid', _filledWells: 2 }) }
    const plate3 = { state: 'valid', plate: plateFactory({ uuid: 'plate-3-uuid', _filledWells: 3 }) }
    const plate4 = { state: 'valid', plate: plateFactory({ uuid: 'plate-4-uuid', _filledWells: 5 }) }
    const wrapper = wrapperFactory()
    wrapper.vm.updatePlate(1, plate1)
    wrapper.vm.updatePlate(2, plate2)
    wrapper.vm.updatePlate(3, plate3)
    wrapper.vm.updatePlate(4, plate4)

    wrapper.setData({ requestsWithPlatesFiltered: wrapper.vm.requestsWithPlates })

    expect(wrapper.vm.transfers.valid).toEqual([
      { source_plate: 'plate-1-uuid', pool_index: 1, source_asset: 'plate-1-uuid-well-0', outer_request: 'plate-1-uuid-well-0-source-request-0', new_target: { location: 'A1' } },
      { source_plate: 'plate-1-uuid', pool_index: 1, source_asset: 'plate-1-uuid-well-1', outer_request: 'plate-1-uuid-well-1-source-request-0', new_target: { location: 'C1' } },
      { source_plate: 'plate-1-uuid', pool_index: 1, source_asset: 'plate-1-uuid-well-2', outer_request: 'plate-1-uuid-well-2-source-request-0', new_target: { location: 'E1' } },
      { source_plate: 'plate-1-uuid', pool_index: 1, source_asset: 'plate-1-uuid-well-3', outer_request: 'plate-1-uuid-well-3-source-request-0', new_target: { location: 'G1' } },
      { source_plate: 'plate-2-uuid', pool_index: 2, source_asset: 'plate-2-uuid-well-0', outer_request: 'plate-2-uuid-well-0-source-request-0', new_target: { location: 'B1' } },
      { source_plate: 'plate-2-uuid', pool_index: 2, source_asset: 'plate-2-uuid-well-1', outer_request: 'plate-2-uuid-well-1-source-request-0', new_target: { location: 'D1' } },
      { source_plate: 'plate-3-uuid', pool_index: 3, source_asset: 'plate-3-uuid-well-0', outer_request: 'plate-3-uuid-well-0-source-request-0', new_target: { location: 'A2' } },
      { source_plate: 'plate-3-uuid', pool_index: 3, source_asset: 'plate-3-uuid-well-1', outer_request: 'plate-3-uuid-well-1-source-request-0', new_target: { location: 'C2' } },
      { source_plate: 'plate-3-uuid', pool_index: 3, source_asset: 'plate-3-uuid-well-2', outer_request: 'plate-3-uuid-well-2-source-request-0', new_target: { location: 'E2' } },
      { source_plate: 'plate-4-uuid', pool_index: 4, source_asset: 'plate-4-uuid-well-0', outer_request: 'plate-4-uuid-well-0-source-request-0', new_target: { location: 'B2' } },
      { source_plate: 'plate-4-uuid', pool_index: 4, source_asset: 'plate-4-uuid-well-1', outer_request: 'plate-4-uuid-well-1-source-request-0', new_target: { location: 'D2' } },
      { source_plate: 'plate-4-uuid', pool_index: 4, source_asset: 'plate-4-uuid-well-2', outer_request: 'plate-4-uuid-well-2-source-request-0', new_target: { location: 'F2' } },
      { source_plate: 'plate-4-uuid', pool_index: 4, source_asset: 'plate-4-uuid-well-3', outer_request: 'plate-4-uuid-well-3-source-request-0', new_target: { location: 'H2' } },
      { source_plate: 'plate-4-uuid', pool_index: 4, source_asset: 'plate-4-uuid-well-4', outer_request: 'plate-4-uuid-well-4-source-request-0', new_target: { location: 'J2' } }
    ])
  })

  it('passes on the layout', () => {
    const plate1 = { state: 'valid', plate: plateFactory({ uuid: 'plate-1-uuid', _filledWells: 4 }) }
    const plate2 = { state: 'valid', plate: plateFactory({ uuid: 'plate-2-uuid', _filledWells: 2 }) }
    const plate3 = { state: 'valid', plate: plateFactory({ uuid: 'plate-3-uuid', _filledWells: 3 }) }
    const plate4 = { state: 'valid', plate: plateFactory({ uuid: 'plate-4-uuid', _filledWells: 5 }) }
    const wrapper = wrapperFactory()
    wrapper.vm.updatePlate(1, plate1)
    wrapper.vm.updatePlate(2, plate2)
    wrapper.vm.updatePlate(3, plate3)
    wrapper.vm.updatePlate(4, plate4)

    wrapper.setData({ requestsWithPlatesFiltered: wrapper.vm.requestsWithPlates })

    expect(wrapper.vm.targetWells).toEqual({
      'A1': { pool_index: 1 },
      'C1': { pool_index: 1 },
      'E1': { pool_index: 1 },
      'G1': { pool_index: 1 },
      'B1': { pool_index: 2 },
      'D1': { pool_index: 2 },
      'A2': { pool_index: 3 },
      'C2': { pool_index: 3 },
      'E2': { pool_index: 3 },
      'B2': { pool_index: 4 },
      'D2': { pool_index: 4 },
      'F2': { pool_index: 4 },
      'H2': { pool_index: 4 },
      'J2': { pool_index: 4 }
    })
  })
})
