// Import the component being tested
import { shallowMount } from '@vue/test-utils'
import CustomTaggedPlate from './CustomTaggedPlate.vue'
import localVue from 'test_support/base_vue.js'
import { jsonCollectionFactory } from 'test_support/factories'
import flushPromises from 'flush-promises'
// import mockApi from 'test_support/mock_api'

describe('CustomTaggedPlate', () => {
  const plateUuid = 'afabla7e-9498-42d6-964e-50f61ded6d9a'
  const nullPlate = { data: [] }
  const goodPlate = jsonCollectionFactory('plate', [{ uuid: plateUuid }])
  // const badPlate = jsonCollectionFactory('plate', [{ uuid: plateUuid }])
  // const goodTagGroups = jsonCollectionFactory('tag_group', [{ id: '1', name: 'Tag Group 1', tags: [{ index: 1, oligo: 'CTAGCTAG' }, { index: 2, oligo: 'TTATACGA'}] }])
  // const nullTagGroups = { data: [] }

  const wrapperFactorySearching = function(api = mockApi()) {
    return mount(CustomTaggedPlate, {
      propsData: {
        devourApi: api.devour,
        parentUuid: plateUuid,
        state: 'searching',
        parentPlate: null,
        progressMessage: 'Fetching parent plate details and tag groups...',
        // offsetTagsByMin: 1,
        // offsetTagsByMax: 96,
        // offsetTagsByStep: 1,
        // offsetTagsByOptions: {},
        // form: {
        //   tagPlateBarcode: null,
        //   tag1Group: null,
        //   tag2Group: null,
        //   byPoolPlateOption: null,
        //   byRowColOption: null,
        //   offsetTagsByOption: 1,
        //   tagsPerWellOption: 1
        // }
      },
      localVue
    })
  }

  // it('renders a loading modal whilst searching for the parent plate and tag groups', () => {
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

  // it('disables creation if there are no source plate sample wells', () => {

  // it('sets the tag groups if a valid plate is scanned'), () => {

  // it('disables the tag plate scan box if a tag group is chosen'), () => {

  // it('substitutes tags based on selections', () => {

  // it('enables creation if valid tags are chosen', () => {

  // it('disables creation if tag clashes are disabled', () => {

  // it('sends a post request when the button is clicked', async () => {


})
