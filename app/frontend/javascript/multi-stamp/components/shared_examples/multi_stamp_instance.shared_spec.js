// Note the .shared_spec.js file suffix: while not a formal convention, it indicates that this
// file contains specs that are shared across multiple test files - while not being automatically
// run as a test suite itself.

// Import the component being tested
import { mount } from '@vue/test-utils'
import { plateFactory, wellFactory, requestFactory } from '@/javascript/test_support/factories.js'

const sharedSpecs = (args) => {
  const subject = args.subject
  const mockLocation = {}

  describe('a MultiStamp instance', () => {
    const wrapperFactory = function (options = {}) {
      // Not ideal using mount here, but having massive trouble
      // triggering change events on unmounted components
      return mount(subject, {
        props: {
          targetRows: '16',
          targetColumns: '24',
          sourcePlates: '4',
          purposeUuid: 'test',
          requestsFilter: 'null',
          targetUrl: 'example/example',
          locationObj: mockLocation,
          transfersLayout: 'quadrant',
          transfersCreator: 'multi-stamp',
          ...options,
        },
        global: {
          stubs: {
            LbPlate: true,
            PlateSummary: true,
          },
        },
      })
    }

    it('disables creation if there are no plates', () => {
      const wrapper = wrapperFactory()

      expect(wrapper.vm.valid).toEqual(false)
    })

    it('enables creation when there are all valid plates', () => {
      const wrapper = wrapperFactory()
      const plate1 = {
        state: 'valid',
        plate: plateFactory({ uuid: 'plate-uuid-1', _filledWells: 4 }),
      }
      const plate2 = {
        state: 'valid',
        plate: plateFactory({ uuid: 'plate-uuid-2', _filledWells: 4 }),
      }
      wrapper.vm.updatePlate(1, plate1)
      wrapper.vm.updatePlate(2, plate2)

      wrapper.setData({
        requestsWithPlatesFiltered: wrapper.vm.requestsWithPlates,
      })
      wrapper.setData({
        transfersCreatorObj: { isValid: true, extraParams: (_) => {} },
      })

      expect(wrapper.vm.valid).toEqual(true)
    })

    it('disables creation when there are no possible transfers', () => {
      const wrapper = wrapperFactory()

      wrapper.setData({ requestsWithPlatesFiltered: [] })

      expect(wrapper.findComponent({ name: 'b-button' }).vm.disabled).toEqual(true)
    })

    it('disables creation when there are some invalid plates', () => {
      const wrapper = wrapperFactory()
      const plate1 = {
        state: 'valid',
        plate: plateFactory({ uuid: 'plate-uuid-1', _filledWells: 4 }),
      }
      const plate2 = {
        state: 'invalid',
        plate: plateFactory({ uuid: 'plate-uuid-2', _filledWells: 4 }),
      }
      wrapper.vm.updatePlate(1, plate1)
      wrapper.vm.updatePlate(2, plate2)

      wrapper.setData({
        requestsWithPlatesFiltered: wrapper.vm.requestsWithPlates,
      })

      expect(wrapper.vm.valid).toEqual(false)
    })

    it('passes on the layout', () => {
      const plate1 = {
        state: 'valid',
        plate: plateFactory({ uuid: 'plate-1-uuid', _filledWells: 4 }),
      }
      const plate2 = {
        state: 'valid',
        plate: plateFactory({ uuid: 'plate-2-uuid', _filledWells: 2 }),
      }
      const plate3 = {
        state: 'valid',
        plate: plateFactory({ uuid: 'plate-3-uuid', _filledWells: 3 }),
      }
      const plate4 = {
        state: 'valid',
        plate: plateFactory({ uuid: 'plate-4-uuid', _filledWells: 5 }),
      }
      const wrapper = wrapperFactory()
      wrapper.vm.updatePlate(1, plate1)
      wrapper.vm.updatePlate(2, plate2)
      wrapper.vm.updatePlate(3, plate3)
      wrapper.vm.updatePlate(4, plate4)

      wrapper.setData({
        requestsWithPlatesFiltered: wrapper.vm.requestsWithPlates,
      })

      expect(wrapper.vm.targetWells).toEqual({
        A1: { colour_index: 1 },
        C1: { colour_index: 1 },
        E1: { colour_index: 1 },
        G1: { colour_index: 1 },
        B1: { colour_index: 2 },
        D1: { colour_index: 2 },
        A2: { colour_index: 3 },
        C2: { colour_index: 3 },
        E2: { colour_index: 3 },
        B2: { colour_index: 4 },
        D2: { colour_index: 4 },
        F2: { colour_index: 4 },
        H2: { colour_index: 4 },
        J2: { colour_index: 4 },
      })
    })

    it('does not display an alert if no invalid transfers are present', () => {
      const plate1 = {
        state: 'valid',
        plate: plateFactory({ uuid: 'plate-1-uuid', _filledWells: 4 }),
      }
      const wrapper = wrapperFactory()
      wrapper.vm.updatePlate(1, plate1)

      wrapper.setData({
        requestsWithPlatesFiltered: wrapper.vm.requestsWithPlates,
      })

      expect(wrapper.vm.duplicatedTransfers).toEqual([])
      expect(wrapper.vm.excessTransfers).toEqual([])
      expect(wrapper.vm.transfersError).toEqual('')
    })

    it('displays the correct error message when scanned plate contains duplicated requests', () => {
      const requests1 = [requestFactory({ uuid: 'req-1-uuid' }), requestFactory({ uuid: 'req-2-uuid' })]
      const well1 = wellFactory({
        uuid: 'well-1-uuid',
        requests_as_source: requests1,
        position: { name: 'A1' },
      })
      const plate1 = {
        state: 'valid',
        plate: plateFactory({ uuid: 'plate-1-uuid', wells: [well1] }),
      }
      const wrapper = wrapperFactory()
      wrapper.vm.updatePlate(1, plate1)

      wrapper.setData({
        requestsWithPlatesFiltered: wrapper.vm.requestsWithPlates,
      })

      expect(wrapper.vm.duplicatedTransfers.length).toEqual(1)
      expect(wrapper.vm.transfersError).toEqual(
        'This would result in multiple transfers into the same well. Check if the source plates (DN1S) have more than one active submission.',
      )
    })

    describe('defaultVolume', () => {
      it('works when not specifying default volume', () => {
        const wrapper = wrapperFactory()
        expect(wrapper.vm.defaultVolumeNumber).toEqual(null)
      })

      describe('when specifying a default volume', () => {
        const wrapperFactory = function (options = {}) {
          // Not ideal using mount here, but having massive trouble
          // triggering change events on unmounted components
          return mount(subject, {
            props: {
              targetRows: '16',
              targetColumns: '24',
              sourcePlates: '4',
              purposeUuid: 'test',
              requestsFilter: 'null',
              targetUrl: 'example/example',
              locationObj: mockLocation,
              transfersLayout: 'quadrant',
              transfersCreator: 'multi-stamp',
              defaultVolume: '34',
              ...options,
            },
            global: {
              stubs: {
                LbPlate: true,
              },
            },
          })
        }

        it('loads the default volume from properties', () => {
          const wrapper = wrapperFactory()
          expect(wrapper.vm.defaultVolumeNumber).toEqual(34)
        })
      })
    })
  })
}

export default sharedSpecs
