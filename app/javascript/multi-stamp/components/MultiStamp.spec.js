import { shallowMount } from '@vue/test-utils'

// // Import the component being tested
import MultiStamp from './MultiStamp.vue'
import itBehavesLikeMultiStamp from './shared_examples/multi_stamp_instance.spec'
import flushPromises from 'flush-promises'
// // Import the component being tested
import localVue from 'test_support/base_vue.js'
import { plateFactory, wellFactory, requestFactory } from 'test_support/factories'

import MockAdapter from 'axios-mock-adapter'

const mockLocation = {}

describe('MultiStamp', () => {
  itBehavesLikeMultiStamp({subject: MultiStamp})

  describe('with any other functionality', () => {

    const wrapperFactory = function(options = {}) {

      // Not ideal using mount here, but having massive trouble
      // triggering change events on unmounted components
      return shallowMount(MultiStamp, {
        propsData: {
          targetRows: '16',
          targetColumns: '24',
          sourcePlates: '4',
          purposeUuid: 'test',
          requestsFilter: 'null',
          targetUrl: 'example/example',
          locationObj: mockLocation,
          transfersLayout: 'quadrant',
          transfersCreator: 'multi-stamp',
          ...options
        },
        localVue
      })
    }

    it('sends a post request when the button is clicked', async () => {
      let mock = new MockAdapter(localVue.prototype.$axios)
  
      const plate = { state: 'valid', plate: plateFactory({ uuid: 'plate-uuid', _filledWells: 1 }) }
      const wrapper = wrapperFactory({}, mockLocation)
      wrapper.vm.updatePlate(1, plate)
  
      wrapper.setData({ requestsWithPlatesFiltered: wrapper.vm.requestsWithPlates })
      wrapper.setData({ transfersCreatorObj: { isValid: true, extraParams: (_) => {} } })
  
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
      wrapper.setData({ transfersCreatorObj: { isValid: true, extraParams: (_) => {} } })
  
      expect(wrapper.vm.apiTransfers()).toEqual([
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
      wrapper.setData({ transfersCreatorObj: { isValid: true, extraParams: (_) => {} } })
  
      expect(wrapper.vm.apiTransfers()).toEqual([
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

    it('display "excess transfers" when too many transfers for the target are scanned', () => {
      const plate1 = { state: 'valid', plate: plateFactory({ uuid: 'plate-1-uuid', _filledWells: 4 }) }
      const wrapper = wrapperFactory({ targetRows: '1', targetColumns: '1' })
      wrapper.vm.updatePlate(1, plate1)
  
      wrapper.setData({ requestsWithPlatesFiltered: wrapper.vm.requestsWithPlates })
  
      expect(wrapper.vm.excessTransfers.length).toEqual(3)
      expect(wrapper.vm.transfersError).toEqual('excess transfers')
    })
  
    it('display "excess transfers" when too many transfers for the target are scanned over multiple plates', () => {
      const plate1 = { state: 'valid', plate: plateFactory({ uuid: 'plate-1-uuid', _filledWells: 4 }) }
      const plate2 = { state: 'valid', plate: plateFactory({ uuid: 'plate-2-uuid', _filledWells: 4 }) }
      const wrapper = wrapperFactory({ targetRows: '2', targetColumns: '2' })
      wrapper.vm.updatePlate(1, plate1)
      wrapper.vm.updatePlate(2, plate2)
  
      wrapper.setData({ requestsWithPlatesFiltered: wrapper.vm.requestsWithPlates })
  
      expect(wrapper.vm.excessTransfers.length).toEqual(4)
      expect(wrapper.vm.transfersError).toEqual('excess transfers')
    })    
  })
})

