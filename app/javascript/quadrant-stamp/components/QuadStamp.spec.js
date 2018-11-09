// Import the component being tested
import { shallowMount } from '@vue/test-utils'
import QuadStamp from 'quadrant-stamp/components/QuadStamp.vue'
import localVue from '_test_/support/base_vue'
import { plateFactory, wellFactory, requestFactory } from '_test_/support/factories'
import moxios from 'moxios'

const mockLocation = {}

describe('QuadStamp', () => {
  const wrapperFactory = function() {
    // Not ideal using mount here, but having massive trouble
    // triggering change events on unmounted components
    return shallowMount(QuadStamp, {
      propsData: {
        targetRows: 16,
        targetColumns: 24,
        sourcePlateNumber: 4,
        purposeUuid: 'test',
        targetUrl: 'example/example',
        locationObj: mockLocation
      },
      localVue
    })
  }

  it('provides a list of filter options', () => {
    const requestsAsSource1 = [
      requestFactory({primerPanel: {name: 'Common Panel'}}),
      requestFactory({primerPanel: {name: 'Distinct Panel'}})
    ]
    const requestsOnAliquot1 = requestFactory({primerPanel: {name: 'Shared Panel'}})
    const requestsAsSource2 = [
      requestFactory({primerPanel: {name: 'Common Panel'}}),
      requestFactory({primerPanel: {name: 'Shared Panel'}})
    ]
    const wells1 = [ wellFactory({ requestsAsSource: requestsAsSource1, aliquots: [{request: requestsOnAliquot1}] }) ]
    const wells2 = [ wellFactory({ requestsAsSource: requestsAsSource2 }) ]
    const plate1 = { state: 'valid', plate: plateFactory({ uuid: 'plate-1-uuid', wells: wells1 }) }
    const plate2 = { state: 'valid', plate: plateFactory({ uuid: 'plate-2-uuid', wells: wells2 }) }
    const wrapper = wrapperFactory()

    wrapper.vm.updatePlate(1, plate1)
    wrapper.vm.updatePlate(2, plate2)

    // Feels like we should have easier access to these properties
    expect(wrapper.find('bformradiogroup-stub').vm.$attrs.options).toEqual(['Common Panel', 'Shared Panel'])
  })

  it('disables creation if there are no plates', () => {
    const wrapper = wrapperFactory()

    expect(wrapper.vm.valid).toEqual(false)
  })

  it('enables creation when there are all valid plates', () => {
    const wrapper = wrapperFactory()
    const plate1 = { state: 'valid', plate: plateFactory({ uuid: 'plate-uuid', filledWells: 4 }) }
    const plate2 = { state: 'valid', plate: plateFactory({ uuid: 'plate-uuid', filledWells: 4 }) }
    wrapper.vm.updatePlate(1, plate1)
    wrapper.vm.updatePlate(1, plate2)
    // Consider auto-selecting a single panel
    wrapper.setData({ primerPanel: 'Test panel' })

    expect(wrapper.vm.valid).toEqual(true)
  })

  it('disables creation when there are some invalid plates', () => {
    const wrapper = wrapperFactory()
    const plate1 = { state: 'valid', plate: plateFactory({ uuid: 'plate-uuid', filledWells: 4 }) }
    const plate2 = { state: 'invalid', plate: plateFactory({ uuid: 'plate-uuid', filledWells: 4 }) }
    wrapper.vm.updatePlate(1, plate1)
    wrapper.vm.updatePlate(1, plate2)
    // Consider auto-selecting a single panel
    wrapper.setData({ primerPanel: 'Test panel' })

    expect(wrapper.vm.valid).toEqual(false)
  })

  it('sends a post request when the button is clicked', (done) => {
    moxios.withMock(function(){
      const plate = { state: 'valid', plate: plateFactory({ uuid: 'plate-uuid', filledWells: 1 }) }
      const wrapper = wrapperFactory()
      wrapper.vm.updatePlate(1, plate)

      // Consider auto-selecting a single panel
      wrapper.setData({ primerPanel: 'Test panel' })

      const expectedPayload = { plate: {
        purpose_uuid: 'test',
        parent_uuid: 'plate_uuid',
        transfers: [
          { source_plate: 'plate-uuid', pool_index: 1, source_asset: 'plate-uuid-well-0', outer_request: 'plate-uuid-well-0-source-request-0', new_target: { location: 'A1' } }
        ]
      }}

      mockLocation.href = null

      // Ideally we'd emit the event from the button component, but I'm having difficulty.
      wrapper.vm.createPlate()

      moxios.wait(function () {
        let request = moxios.requests.mostRecent()
        expect(request.url).toEqual('example/example')

        request.respondWith({
          status: 201,
          response: { redirect: 'http://wwww.example.com' }
        }).then(function() {
          expect(mockLocation.href).toEqual('http://wwww.example.com')
          done()
        }).catch(()=>{
          expect('This test').toEqual('should never be run')
        })
      })
    })
  })

  it('disables creation when there are no possible transfers', () => {
    const wrapper = wrapperFactory()
    const plate1 = { state: 'valid', plate: plateFactory({ uuid: 'plate-uuid', filledWells: 4 }) }
    wrapper.vm.updatePlate(1, plate1)

    expect(wrapper.find('bbutton-stub').element.getAttribute('disabled')).toEqual('true')
  })

  it('filters requests based on panel options', () => {
    const requestsAsSource1 = [
      requestFactory({ uuid: 'other-request-1', primerPanel: {name: 'Common Panel'}}),
      requestFactory({ uuid: 'target-request-1', primerPanel: {name: 'Distinct Panel'}})
    ]
    const requestsOnAliquot1 = requestFactory({ uuid: 'target-request-2', primerPanel: {name: 'Shared Panel'}})
    const wells1 = [ wellFactory({ requestsAsSource: requestsAsSource1, aliquots: [{request: requestsOnAliquot1}] }) ]
    const plate1 = { state: 'valid', plate: plateFactory({ wells: wells1 }) }

    const wrapper = wrapperFactory()

    wrapper.vm.updatePlate(1, plate1)
    wrapper.setData({ primerPanel: 'Distinct Panel' })

    expect(wrapper.vm.transfers).toEqual([
      { source_plate: 'plate-uuid', pool_index: 1, source_asset: 'well-uuid', outer_request: 'target-request-1', new_target: { location: 'A1' } }
    ])

    wrapper.setData({ primerPanel: 'Shared Panel' })

    expect(wrapper.vm.transfers).toEqual([
      { source_plate: 'plate-uuid', pool_index: 1, source_asset: 'well-uuid', outer_request: 'target-request-2', new_target: { location: 'A1' } }
    ])
  })

  it('calculates transfers', () => {
    const plate = { state: 'valid', plate: plateFactory({ uuid: 'plate-uuid', filledWells: 4 }) }
    const wrapper = wrapperFactory()
    wrapper.vm.updatePlate(1, plate)

    // Consider auto-selecting a single panel
    wrapper.setData({ primerPanel: 'Test panel' })

    expect(wrapper.vm.transfers).toEqual([
      { source_plate: 'plate-uuid', pool_index: 1, source_asset: 'plate-uuid-well-0', outer_request: 'plate-uuid-well-0-source-request-0', new_target: { location: 'A1' } },
      { source_plate: 'plate-uuid', pool_index: 1, source_asset: 'plate-uuid-well-1', outer_request: 'plate-uuid-well-1-source-request-0', new_target: { location: 'C1' } },
      { source_plate: 'plate-uuid', pool_index: 1, source_asset: 'plate-uuid-well-2', outer_request: 'plate-uuid-well-2-source-request-0', new_target: { location: 'E1' } },
      { source_plate: 'plate-uuid', pool_index: 1, source_asset: 'plate-uuid-well-3', outer_request: 'plate-uuid-well-3-source-request-0', new_target: { location: 'G1' } }
    ])
  })

  it('handles multiple plates', () => {
    const plate1 = { state: 'valid', plate: plateFactory({ uuid: 'plate-1-uuid', filledWells: 4 }) }
    const plate2 = { state: 'valid', plate: plateFactory({ uuid: 'plate-2-uuid', filledWells: 2 }) }
    const plate3 = { state: 'valid', plate: plateFactory({ uuid: 'plate-3-uuid', filledWells: 3 }) }
    const plate4 = { state: 'valid', plate: plateFactory({ uuid: 'plate-4-uuid', filledWells: 5 }) }
    const wrapper = wrapperFactory()
    wrapper.vm.updatePlate(1, plate1)
    wrapper.vm.updatePlate(2, plate2)
    wrapper.vm.updatePlate(3, plate3)
    wrapper.vm.updatePlate(4, plate4)

    // Consider auto-selecting a single panel
    wrapper.setData({ primerPanel: 'Test panel' })

    expect(wrapper.vm.transfers).toEqual([
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
    const plate1 = { state: 'valid', plate: plateFactory({ uuid: 'plate-1-uuid', filledWells: 4 }) }
    const plate2 = { state: 'valid', plate: plateFactory({ uuid: 'plate-2-uuid', filledWells: 2 }) }
    const plate3 = { state: 'valid', plate: plateFactory({ uuid: 'plate-3-uuid', filledWells: 3 }) }
    const plate4 = { state: 'valid', plate: plateFactory({ uuid: 'plate-4-uuid', filledWells: 5 }) }
    const wrapper = wrapperFactory()
    wrapper.vm.updatePlate(1, plate1)
    wrapper.vm.updatePlate(2, plate2)
    wrapper.vm.updatePlate(3, plate3)
    wrapper.vm.updatePlate(4, plate4)

    // Consider auto-selecting a single panel
    wrapper.setData({ primerPanel: 'Test panel' })

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
