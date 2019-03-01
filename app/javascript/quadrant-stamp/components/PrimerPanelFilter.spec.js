import { shallowMount } from '@vue/test-utils'
import PrimerPanelFilter from './PrimerPanelFilter.vue'
import localVue from 'test_support/base_vue.js'
import { plateFactory, wellFactory, requestFactory } from 'test_support/factories.js'

const requests = []

describe('PrimerPanelFilter', () => {
  const wrapperFactory = function() {
    return shallowMount(PrimerPanelFilter, {
      propsData: {
        requestsWithPlates: requests
      },
      localVue
    })
  }

  xit('provides a list of filter options', () => {
    const requestsAsSource1 = [
      requestFactory({primerPanel: {name: 'Common Panel'}}),
      requestFactory({primerPanel: {name: 'Distinct Panel'}})
    ]
    const requestsOnAliquot1 = requestFactory({primerPanel: {name: 'Shared Panel'}})
    const requestsAsSource2 = [
      requestFactory({primerPanel: {name: 'Common Panel'}}),
      requestFactory({primerPanel: {name: 'Shared Panel'}})
    ]
    const wells1 = [ wellFactory({ requests_as_source: requestsAsSource1, aliquots: [{request: requestsOnAliquot1}] }) ]
    const wells2 = [ wellFactory({ requests_as_source: requestsAsSource2 }) ]
    const plate1 = { state: 'valid', plate: plateFactory({ uuid: 'plate-1-uuid', wells: wells1 }) }
    const plate2 = { state: 'valid', plate: plateFactory({ uuid: 'plate-2-uuid', wells: wells2 }) }
    const wrapper = wrapperFactory()

    wrapper.vm.updatePlate(1, plate1)
    wrapper.vm.updatePlate(2, plate2)

    // Feels like we should have easier access to these properties
    expect(wrapper.find('bformradiogroup-stub').vm.$attrs.options).toEqual(['Common Panel', 'Shared Panel'])
  })

  xit('filters requests based on panel options', () => {
    const requestsAsSource1 = [
      requestFactory({ uuid: 'other-request-1', primer_panel: {name: 'Common Panel'}}),
      requestFactory({ uuid: 'target-request-1', primer_panel: {name: 'Distinct Panel'}})
    ]
    const requestsOnAliquot1 = requestFactory({ uuid: 'target-request-2', primer_panel: {name: 'Shared Panel'}})
    const wells1 = [ wellFactory({ requests_as_source: requestsAsSource1, aliquots: [{request: requestsOnAliquot1}] }) ]
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
})
