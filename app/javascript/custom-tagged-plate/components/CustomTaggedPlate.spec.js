// Import the component being tested
import { shallowMount } from '@vue/test-utils'
import CustomTaggedPlate from './CustomTaggedPlate.vue'
import localVue from 'test_support/base_vue.js'
import { plateFactory, wellFactory, requestFactory } from 'test_support/factories.js'
import flushPromises from 'flush-promises'
import axios from 'axios'
import MockAdapter from 'axios-mock-adapter'

describe('CustomTaggedPlate', () => {
  const wrapperFactory = function() {
    return shallowMount(CustomTaggedPlate, {
      propsData: {
        sequencescapeApi: 'http://localhost:3000/api/v2',
        purposeUuid: 'PURP_UUID_1234',
        targetUrl: '/test/SOME_UUID/children',
        parentUuid: 'PARN_UUID_1234'
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

  // it('disables creation if there are no source plate sample wells', () => {

  // it('sets the tag groups if a valid plate is scanned'), () => {

  // it('disables the tag plate scan box if a tag group is chosen'), () => {

  // it('substitutes tags based on selections', () => {

  // it('enables creation if valid tags are chosen', () => {

  // it('disables creation if tag clashes are disabled', () => {

  // it('sends a post request when the button is clicked', async () => {


})
