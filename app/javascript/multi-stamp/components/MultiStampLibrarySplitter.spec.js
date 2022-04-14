import { shallowMount } from '@vue/test-utils'
import localVue from 'test_support/base_vue.js'
import flushPromises from 'flush-promises'

import MockAdapter from 'axios-mock-adapter'

const mockLocation = {}

// Import the component being tested
import MultiStampLibrarySplitter from './MultiStampLibrarySplitter.js'
import itBehavesLikeMultiStamp from './shared_examples/multi_stamp_instance.spec'

describe('MultiStampLibrarySplitter', () => {
  itBehavesLikeMultiStamp({ subject: MultiStampLibrarySplitter })

  describe('with the extra functionality', () => {
    const wrapperFactory = function (options = {}) {
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

    describe('with several input plates', () => {
      it('sends a post request when the button is clicked', async () => {
        // This will check receiving 3 plates, plate 1 and 2 received in positions
        // 1 and 2; and plate 3 received in position 4, so there will be a gap for
        // the wells corresponding to the missing plate at position 3
        let mock = new MockAdapter(localVue.prototype.$axios)

        const plateContent = {
          uuid: 'plate-uuid',
          wells: [
            {
              uuid: 'well-1',
              position: { name: 'A1' },
              aliquots: [{}],
              requests_as_source: [
                { uuid: 'outer-1', library_type: 'Lib A' },
                { uuid: 'outer-2', library_type: 'Lib B' },
              ],
            },
            {
              uuid: 'well-2',
              position: { name: 'B2' },
              aliquots: [{}],
              requests_as_source: [
                { uuid: 'outer-3', library_type: 'Lib A' },
                { uuid: 'outer-4', library_type: 'Lib B' },
              ],
            },
            {
              uuid: 'well-3',
              position: { name: 'A3' },
              aliquots: [{}],
              requests_as_source: [
                { uuid: 'outer-5', library_type: 'Lib A' },
                { uuid: 'outer-6', library_type: 'Lib B' },
              ],
            },
          ],
        }

        const plate2Content = {
          uuid: 'plate2-uuid',
          wells: [
            {
              uuid: 'well2-1',
              position: { name: 'A1' },
              aliquots: [{}],
              requests_as_source: [
                { uuid: 'outer2-1', library_type: 'Lib A' },
                { uuid: 'outer2-2', library_type: 'Lib B' },
              ],
            },
            {
              uuid: 'well2-2',
              position: { name: 'B2' },
              aliquots: [{}],
              requests_as_source: [
                { uuid: 'outer2-3', library_type: 'Lib A' },
                { uuid: 'outer2-4', library_type: 'Lib B' },
              ],
            },
            {
              uuid: 'well2-3',
              position: { name: 'A3' },
              aliquots: [{}],
              requests_as_source: [
                { uuid: 'outer2-5', library_type: 'Lib A' },
                { uuid: 'outer2-6', library_type: 'Lib B' },
              ],
            },
          ],
        }

        const plate4Content = {
          uuid: 'plate4-uuid',
          wells: [
            {
              uuid: 'well4-3',
              position: { name: 'H3' },
              aliquots: [{}],
              requests_as_source: [
                { uuid: 'outer4-5', library_type: 'Lib A' },
                { uuid: 'outer4-6', library_type: 'Lib B' },
              ],
            },
          ],
        }

        const plate = {
          state: 'valid',
          plate: plateContent, //plateFactory({ uuid: 'plate-uuid', _filledWells: 1 }),
        }
        const plate2 = {
          state: 'valid',
          plate: plate2Content, //plateFactory({ uuid: 'plate-uuid', _filledWells: 1 }),
        }

        const plate4 = {
          state: 'valid',
          plate: plate4Content, //plateFactory({ uuid: 'plate-uuid', _filledWells: 1 }),
        }

        const wrapper = wrapperFactory({}, mockLocation)

        wrapper.vm.updatePlate(1, plate)
        wrapper.vm.updatePlate(2, plate2)

        wrapper.vm.updatePlate(4, plate4)

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

              {
                source_plate: 'plate2-uuid',
                pool_index: 2,
                source_asset: 'well2-1',
                outer_request: 'outer2-1',
                new_target: { location: 'A4' },
              },
              {
                source_plate: 'plate2-uuid',
                pool_index: 2,
                source_asset: 'well2-2',
                outer_request: 'outer2-3',
                new_target: { location: 'B5' },
              },
              {
                source_plate: 'plate2-uuid',
                pool_index: 2,
                source_asset: 'well2-3',
                outer_request: 'outer2-5',
                new_target: { location: 'A6' },
              },
              {
                source_plate: 'plate4-uuid',
                pool_index: 4,
                source_asset: 'well4-3',
                outer_request: 'outer4-5',
                new_target: { location: 'H12' },
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

              {
                source_plate: 'plate2-uuid',
                pool_index: 2,
                source_asset: 'well2-1',
                outer_request: 'outer2-2',
                new_target: { location: 'A4' },
              },
              {
                source_plate: 'plate2-uuid',
                pool_index: 2,
                source_asset: 'well2-2',
                outer_request: 'outer2-4',
                new_target: { location: 'B5' },
              },
              {
                source_plate: 'plate2-uuid',
                pool_index: 2,
                source_asset: 'well2-3',
                outer_request: 'outer2-6',
                new_target: { location: 'A6' },
              },
              {
                source_plate: 'plate4-uuid',
                pool_index: 4,
                source_asset: 'well4-3',
                outer_request: 'outer4-6',
                new_target: { location: 'H12' },
              },
            ],
          },
        }

        var payloads = [plate1Payload, plate2Payload]

        var numCalls = 0
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

        for (var i = 0; i < listChecks.length; i++) {
          var config = listChecks[i]
          var payload = payloads[i]
          expect(config.url).toEqual('example/example')
          expect(config.data).toEqual(JSON.stringify(payload))
        }

        expect(mockLocation.href).toEqual('http://wwww.example.com')
      })
    })
  })
})
