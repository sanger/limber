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
          transfersLayout: 'quadrant',
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

      const plate = {
        state: 'valid',
        plate: plateFactory({ uuid: 'plate-uuid', _filledWells: 1 }),
      }
      const wrapper = wrapperFactory({}, mockLocation)
      wrapper.vm.updatePlate(1, plate)

      wrapper.setData({
        requestsWithPlatesFiltered: wrapper.vm.requestsWithPlates,
      })
      wrapper.setData({
        transfersCreatorObj: { isValid: true, extraParams: (_) => {} },
      })

      const expectedPayload = {
        plate: {
          parent_uuid: 'plate-uuid',
          purpose_uuid: 'test',
          transfers: [
            {
              source_plate: 'plate-uuid',
              pool_index: 1,
              source_asset: 'plate-uuid-well-0',
              outer_request: 'plate-uuid-well-0-source-request-0',
              new_target: { location: 'A1' },
            },
          ],
        },
      }

      let numCalls = 0
      mockLocation.href = null
      mock.onPost().reply((config) => {
        numCalls = numCalls + 1
        /*expect(config.url).toEqual("example/example");
        expect(config.data).toEqual(JSON.stringify(expectedPayload));
        return [
          201,
          { redirect: "http://wwww.example.com", message: "Creating..." },
        ];*/
      })

      // Ideally we'd emit the event from the button component
      wrapper.vm.createPlate().then((response) => {
        expect(numCalls).toEqual(2)
      })

      await flushPromises()

      expect(mockLocation.href).toEqual('http://wwww.example.com')
    })
  })
})
