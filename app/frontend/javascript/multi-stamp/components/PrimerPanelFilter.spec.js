import { mount } from '@vue/test-utils'
import PrimerPanelFilter from './PrimerPanelFilter.vue'
import { plateFactory, wellFactory, requestFactory } from '@/javascript/test_support/factories.js'
import { requestsFromPlates } from '@/javascript/shared/requestHelpers.js'

describe('PrimerPanelFilter', () => {
  const wrapperFactory = function (requests) {
    return mount(PrimerPanelFilter, {
      props: {
        requestsWithPlates: requests,
      },
      global: {
        stubs: {
          'b-form-radio-group': true,
        },
      },
    })
  }

  it('provides a list of filter options', () => {
    const requestsAsSource1 = [
      requestFactory({ uuid: 'req1-uuid', primer_panel: { name: 'Common Panel' } }),
      requestFactory({ uuid: 'req2-uuid', primer_panel: { name: 'Distinct Panel' } }),
    ]
    const requestsOnAliquot1 = requestFactory({
      primer_panel: { name: 'Shared Panel' },
    })
    const requestsAsSource2 = [
      requestFactory({ uuid: 'req3-uuid', primer_panel: { name: 'Common Panel' } }),
      requestFactory({ uuid: 'req4-uuid', primer_panel: { name: 'Shared Panel' } }),
    ]
    const well1 = wellFactory({
      requests_as_source: requestsAsSource1,
      aliquots: [{ request: requestsOnAliquot1 }],
    })
    const well2 = wellFactory({ requests_as_source: requestsAsSource2 })
    const plateObj1 = {
      state: 'valid',
      plate: plateFactory({ uuid: 'plate-1-uuid', id: '1', wells: [well1] }),
    }
    const plateObj2 = {
      state: 'valid',
      plate: plateFactory({ uuid: 'plate-2-uuid', id: '2', wells: [well2] }),
    }
    const requests = requestsFromPlates([plateObj1, plateObj2])
    const wrapper = wrapperFactory(requests)

    expect(wrapper.findComponent({ name: 'b-form-radio-group' }).vm.options).toEqual(['Common Panel', 'Shared Panel'])
  })

  it('filters requests based on panel options', () => {
    const request1 = requestFactory({
      uuid: 'other-request-1',
      primer_panel: { name: 'Common Panel' },
    })
    const request2 = requestFactory({
      uuid: 'target-request-1',
      primer_panel: { name: 'Distinct Panel' },
    })
    const requestsAsSource1 = [request1, request2]
    const requestsOnAliquot1 = requestFactory({
      uuid: 'target-request-2',
      primer_panel: { name: 'Shared Panel' },
    })
    const well1 = wellFactory({
      requests_as_source: requestsAsSource1,
      aliquots: [{ request: requestsOnAliquot1 }],
    })
    const plateObj1 = {
      state: 'valid',
      plate: plateFactory({ wells: [well1] }),
    }
    const requests = requestsFromPlates([plateObj1])
    const wrapper = wrapperFactory(requests)

    wrapper.setData({ primerPanel: 'Distinct Panel' })

    expect(wrapper.vm.requestsWithPlatesFiltered).toEqual([{ request: request2, well: well1, plateObj: plateObj1 }])

    wrapper.setData({ primerPanel: 'Shared Panel' })

    expect(wrapper.vm.requestsWithPlatesFiltered).toEqual([
      { request: requestsOnAliquot1, well: well1, plateObj: plateObj1 },
    ])
  })

  it('emits requestsWithPlatesFiltered', async () => {
    const request1 = requestFactory({
      uuid: 'other-request-1',
      primer_panel: { name: 'Common Panel' },
    })
    const request2 = requestFactory({
      uuid: 'target-request-1',
      primer_panel: { name: 'Distinct Panel' },
    })
    const requestsAsSource1 = [request1, request2]
    const requestsOnAliquot1 = requestFactory({
      uuid: 'target-request-2',
      primer_panel: { name: 'Shared Panel' },
    })
    const well1 = wellFactory({
      requests_as_source: requestsAsSource1,
      aliquots: [{ request: requestsOnAliquot1 }],
    })
    const plateObj1 = {
      state: 'valid',
      plate: plateFactory({ wells: [well1] }),
    }
    const requests = requestsFromPlates([plateObj1])
    const wrapper = wrapperFactory(requests)

    wrapper.setData({ primerPanel: 'Distinct Panel' })

    await wrapper.vm.$nextTick()

    expect(wrapper.emitted()).toEqual({
      change: [[wrapper.vm.requestsWithPlatesFiltered]],
    })
  })
})
