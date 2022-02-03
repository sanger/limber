import { shallowMount } from '@vue/test-utils'
import localVue from 'test_support/base_vue.js'
import {
  plateFactory,
  wellFactory,
  requestFactory,
} from 'test_support/factories'
import flushPromises from 'flush-promises'

import MockAdapter from 'axios-mock-adapter'

const mockLocation = {}

// Import the component being tested
import MultiStampLibrarySplitter from './MultiStampLibrarySplitter.js'
import itBehavesLikeMultiStamp from './shared_examples/multi_stamp_instance.spec'

describe('MultiStampLibrarySplitter', () => {
  itBehavesLikeMultiStamp({ subject: MultiStampLibrarySplitter })

  describe('with the extra functionality', () => {
    const wrapperFactory = function(options = {}) {
      // Not ideal using mount here, but having massive trouble
      // triggering change events on unmounted components
      return shallowMount(MultiStampLibrarySplitter, {
        propsData: {
          targetRows: '16',
          targetColumns: '24',
          sourcePlates: '4',
          purposeUuid: 'test',
          requestsFilter: 'null',
          targetUrl: 'example/example',
          locationObj: mockLocation,
          transfersLayout: 'sequentialLibrarySplit',
          transfersCreator: 'multi-stamp',
          childrenLibraryTypeToPurposeMappingJson: JSON.stringify({
            'Lib A': 'Purpose A',
            'Lib B': 'Purpose B',
          }),
          ...options,
        },
        localVue,
      })
    }

    it('sends a post request when the button is clicked', async () => {
      let mock = new MockAdapter(localVue.prototype.$axios)

      const plateContent = {
        uuid: 'plate-uuid',
        wells: [
          { uuid: 'well-1', position: { name: 'A1' }, aliquots: [{}], requests_as_source: [ 
            { uuid: 'outer-1', library_type: 'Lib A' },
            { uuid: 'outer-2', library_type: 'Lib B' }
          ] },
          { uuid: 'well-2', position: { name: 'B2' }, aliquots: [{}], requests_as_source: [ 
            { uuid: 'outer-3', library_type: 'Lib A' },
            { uuid: 'outer-4', library_type: 'Lib B' }
          ] },
          { uuid: 'well-3', position: { name: 'A3' }, aliquots: [{}], requests_as_source: [ 
            { uuid: 'outer-5', library_type: 'Lib A' },
            { uuid: 'outer-6', library_type: 'Lib B' }
          ] }
        ]
      }   

      const plate = {
        state: 'valid',
        plate: plateContent //plateFactory({ uuid: 'plate-uuid', _filledWells: 1 }),
      }
      const wrapper = wrapperFactory({}, mockLocation)
      
      wrapper.vm.updatePlate(1, plate)

      wrapper.setData({
        requestsWithPlatesFiltered: wrapper.vm.requestsWithPlates,
      })
      wrapper.setData({
        transfersCreatorObj: { isValid: true, extraParams: (_) => {} },
      })

      const plate1Payload = {
        plate: {
          parent_uuid: 'plate-uuid',
          purpose_uuid: 'Purpose A',
          transfers: [
            {
              source_plate: 'plate-uuid',
              pool_index: 1,
              source_asset: 'well-1',
              outer_request: 'outer-1',
              new_target: { location: 'A1' },
            },
            {
              source_plate: 'plate-uuid',
              pool_index: 1,
              source_asset: 'well-2',
              outer_request: 'outer-3',
              new_target: { location: 'B2' },
            },
            {
              source_plate: 'plate-uuid',
              pool_index: 1,
              source_asset: 'well-3',
              outer_request: 'outer-5',
              new_target: { location: 'A3' },
            },
          ],
        },
      }

      const plate2Payload = {
        plate: {
          parent_uuid: 'plate-uuid',
          purpose_uuid: 'Purpose B',
          transfers: [
            {
              source_plate: 'plate-uuid',
              pool_index: 1,
              source_asset: 'well-1',
              outer_request: 'outer-2',
              new_target: { location: 'A1' },
            },
            {
              source_plate: 'plate-uuid',
              pool_index: 1,
              source_asset: 'well-2',
              outer_request: 'outer-4',
              new_target: { location: 'B2' },
            },
            {
              source_plate: 'plate-uuid',
              pool_index: 1,
              source_asset: 'well-3',
              outer_request: 'outer-6',
              new_target: { location: 'A3' },
            },
          ],
        },
      }

      var payloads = [plate1Payload, plate2Payload]


      var numCalls = 0
      mockLocation.href = null
      var listChecks = []
      mock.onPost().reply((config) => {
        listChecks.push(config)
        numCalls = numCalls + 1
        return [201, { redirect: 'http://wwww.example.com', message: 'Creating...' }]
      })

      // Ideally we'd emit the event from the button component
      wrapper.vm.createPlate()

      await flushPromises()

      expect(numCalls).toEqual(2)

      for (var i=0; i<listChecks.length; i++) {
        var config = listChecks[i]
        var payload = payloads[i]
        expect(config.url).toEqual('example/example')
        expect(config.data).toEqual(JSON.stringify(payload))
      }

      //expect(mockLocation.href).toEqual('http://wwww.example.com')
    })
  })
})
