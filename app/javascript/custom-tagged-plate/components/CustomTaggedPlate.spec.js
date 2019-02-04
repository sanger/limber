// Import the component being tested
import { shallowMount } from '@vue/test-utils'
import CustomTaggedPlate from './CustomTaggedPlate.vue'
import localVue from 'test_support/base_vue.js'
// import { plateFactory, wellFactory, requestFactory, attributesFactory, devourFactory } from 'test_support/factories.js'
import { jsonCollectionFactory } from 'test_support/factories'
import flushPromises from 'flush-promises'
import mockApi from 'test_support/mock_api'

describe('CustomTaggedPlate', () => {
  const sequencescapeApiUrl = 'http://localhost:3000/api/v2'
  const purposeUuid = 'purpose1a-1234-5678-9012-50f61ded6d9a'
  const plateUuid = 'afabla7e-9498-42d6-964e-50f61ded6d9a'
  const targetUrl = '/test/somenew1a-1234-5678-9012-50f61ded6d9a/children'
  const nullPlate = { data: [] }
  const goodPlate = jsonCollectionFactory('plate', [{ uuid: plateUuid }])
  // const badPlate = jsonCollectionFactory('plate', [{ uuid: plateUuid , number_of_columns: 24, number_of_rows: 8 }])

  const wrapperFactory = function(api = mockApi()) {
    return shallowMount(CustomTaggedPlate, {
      propsData: {
        api: api.devour,
        purposeUuid: purposeUuid,
        targetUrl: targetUrl,
        parentUuid: plateUuid
      },
      localVue
    })
  }

  const wrapperFactoryInvalidPlate = function(api = mockApi()) {
    return shallowMount(CustomTaggedPlate, {
      propsData: {
        api: api.devour,
        purposeUuid: purposeUuid,
        targetUrl: targetUrl,
        parentUuid: 'not-a-valid-uuid'
      },
      localVue
    })
  }

  // const expectedResponse = {
  //   data: [
  //     {
  //       id: 12345678,
  //       type: 'plates',
  //       attributes: {
  //         uuid: 'e1e7a5ac-b4f9-11e8-9946-68b599768938',
  //         name: 'Cherrypicked 12345678',
  //         labware_barcode: {
  //           human_barcode: 'DN12345678D'
  //         },
  //         number_of_rows: 8,
  //         number_of_columns: 12,
  //       },
  //       relationships: {
  //         wells: {
  //           data: [
  //             {
  //               type: wells,
  //               id: 23217063
  //             },
  //             {
  //               type: wells,
  //               id: 23217071
  //             },
  //             {
  //               type: wells,
  //               id: 23217079
  //             }
  //           ]
  //         }
  //       }
  //     }
  //   ],
  //   included: [
  //     {
  //       id: 23217063,
  //       type: 'wells',
  //       attributes: {
  //         position: {
  //           name: 'A1'
  //         },
  //       },
  //       relationships: {
  //         aliquots: {
  //           data: [
  //             {
  //               type: 'aliquots',
  //               id: 24856155
  //             }
  //           ]
  //         }
  //       }
  //     },
  //     {
  //       id: 23217071,
  //       type: 'wells',
  //       attributes: {
  //         position: {
  //           name: 'A2'
  //         },
  //       },
  //       relationships: {
  //         aliquots: {
  //           data: [
  //             {
  //               type: 'aliquots',
  //               id: 24856163
  //             }
  //           ]
  //         }
  //       }
  //     },
  //     {
  //       id: 23217079,
  //       type: 'wells',
  //       attributes: {
  //         position: {
  //           name: 'A3'
  //         },
  //       },
  //       relationships: {
  //         aliquots: {
  //           data: [
  //             {
  //               type: 'aliquots',
  //               id: 24856171
  //             }
  //           ]
  //         }
  //       }
  //     },
  //     {
  //       id: 24856155,
  //       type: 'aliquots',
  //      },
  //     {
  //       id: 24856163,
  //       type: 'aliquots',
  //     },
  //     {
  //       id: 24856171,
  //       type: 'aliquots',
  //     }
  //   ]
  // }

  // it('renders a plate panel', async () => {
  //   let mock = new MockAdapter(localVue.prototype.$axios)
  //   mock.onGet('/plates?filter[uuid]=PARN_UUID_1234&limit=1&include=wells.aliquots').reply(200, {
  //     expectedResponse
  //   })

  //   const wrapper = wrapperFactory()

  //   await flushPromises()

  //   expect(wrapper.find('table.plate-view').exists()).toBe(true)
  // })

  // it('on creation gets the parent plate details via the sequencescape api', async () => {
  //   let mock = new MockAdapter(localVue.prototype.$axios)



  //   mock.onGet('/plates?filter[uuid]=PARN_UUID_1234&limit=1&include=wells.aliquots').reply(200, {
  //     expectedResponse
  //   })

  //   const wrapper = wrapperFactory()

  //   await flushPromises()

  //   expect(mock.history.get.length).toBe(1)
  //   expect(wrapper.vm.parentWells.length).toBe(3)
  // })

  // it('renders a tag substitutions list panel', () => {
  // it('renders a tag manipulations panel', () => {

it('is invalid if it can not find the parent plate', async () => {
    const api = mockApi()
    api.mockGet('plates', {
      filter: { uuid: 'not-a-valid-uuid' },
      include: { wells: 'wells.aliquots' },
      fields: { plates: 'labware_barcode,uuid,number_of_rows,number_of_columns' }
    }, nullPlate)
    const wrapper = wrapperFactoryInvalidPlate(api)

    expect(wrapper.vm.parentUuid).toBe('not-a-valid-uuid')
    expect(wrapper.vm.state).toBe('searching')
    expect(wrapper.vm.progressMessage).toBe('Fetching parent plate details...')

    await flushPromises()

    expect(wrapper.vm.state).toBe('invalid')
    expect(wrapper.vm.progressMessage).toBe('Could not find parent plate details')
  })

  // it('is invalid if there are api troubles', async () => {
  //   const api = mockApi()
  //   api.mockGet('plates', {
  //     filter: { barcode: 'Good barcode' },
  //     include: { wells: ['requests_as_source', { aliquots: 'request' }] },
  //     fields: { plates: 'labware_barcode,uuid,number_of_rows,number_of_columns' }
  //   }, { 'errors': [{
  //     title: 'Not good',
  //     detail: 'Very not good',
  //     code: 500,
  //     status: 500
  //   }]}, 500)
  //   const wrapper = wrapperFactory(api)

  //   wrapper.find('input').setValue('Good barcode')
  //   wrapper.find('input').trigger('change')

  //   expect(wrapper.find('.wait-plate').exists()).toBe(true)

  //   await flushPromises()

  //   expect(wrapper.find('.invalid-feedback').text()).toEqual('Nope')
  //   expect(wrapper.emitted()).toEqual({
  //     change: [
  //       [{ state: 'searching', plate: null }],
  //       [{ state: 'invalid', plate: null }]
  //     ]
  //   })
  // })

  // it('is valid if it can find a plate', async () => {
  //   const api = mockApi()
  //   const wrapper = wrapperFactory(api)

  //   api.mockGet('plates',{
  //     include: { wells: ['requests_as_source', { aliquots: 'request' }] },
  //     filter: { barcode: 'DN12345' },
  //     fields: { plates: 'labware_barcode,uuid,number_of_rows,number_of_columns' }
  //   }, goodPlate)

  //   wrapper.find('input').setValue('DN12345')
  //   wrapper.find('input').trigger('change')

  //   expect(wrapper.find('.wait-plate').exists()).toBe(true)

  //   await flushPromises()

  //   expect(wrapper.find('.valid-feedback').text()).toEqual('Great!')

  //   const events = wrapper.emitted()

  //   expect(events.change.length).toEqual(2)
  //   expect(events.change[0]).toEqual([{ state: 'searching', plate: null }])
  //   expect(events.change[1][0].state).toEqual('valid')
  //   expect(events.change[1][0].plate.uuid).toEqual(plateUuid)
  // })

  // it('disables creation if there are no source plate sample wells', () => {

  // it('sets the tag groups if a valid plate is scanned'), () => {

  // it('disables the tag plate scan box if a tag group is chosen'), () => {

  // it('substitutes tags based on selections', () => {

  // it('enables creation if valid tags are chosen', () => {

  // it('disables creation if tag clashes are disabled', () => {

  // it('sends a post request when the button is clicked', async () => {


})
