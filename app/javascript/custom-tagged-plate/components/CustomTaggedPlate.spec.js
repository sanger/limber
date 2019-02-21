// Import the component being tested
import { shallowMount } from '@vue/test-utils'
import CustomTaggedPlate from './CustomTaggedPlate.vue'
import localVue from 'test_support/base_vue.js'

describe('CustomTaggedPlate', () => {
  const plateUuid = 'afabla7e-9498-42d6-964e-50f61ded6d9a'
  const goodParentPlate = {
    id: '1',
    uuid: plateUuid,
    name: 'Test Plate 123456',
    labware_barcode: { human_barcode: 'DN123456D' },
    state: 'passed',
    number_of_rows: 8,
    number_of_columns: 12,
    wells: [
      {
        id: '1',
        position: { name: 'A1' },
        aliquots: [{ id: '1', request: { id: '1', submission: { id: '1', name:'Subm 1' }}}],
        requests_as_source: [{ id: '1', submission: { id: '1', name:'Subm 1' }}]
      },
      {
        id: '2',
        position: { name: 'A2' },
        aliquots: [{ id: '2', request: { id: '2', submission: { id: '1', name:'Subm 1' }}}],
        requests_as_source: [{ id: '2', submission: { id: '1', name:'Subm 1' }}]
      },
      {
        id: '3',
        position: { name: 'A3' },
        aliquots: [{ id: '3', request: { id: '3', submission: { id: '1', name:'Subm 1' }}}],
        requests_as_source: [{ id: '3', submission: { id: '1', name:'Subm 1' }}]
      },
      {
        id: '4',
        position: { name: 'A4' },
        aliquots: [{ id: '4', request: { id: '4', submission: { id: '1', name:'Subm 1' }}}],
        requests_as_source: [{ id: '4', submission: { id: '1', name:'Subm 1' }}]
      }
    ]
  }
  const goodParentPlateWithoutWellRequestsAsResource = {
    id: '1',
    uuid: plateUuid,
    name: 'Test Plate 123456',
    labware_barcode: { human_barcode: 'DN123456D' },
    state: 'passed',
    number_of_rows: 8,
    number_of_columns: 12,
    wells: [
      {
        id: '1',
        position: { name: 'A1' },
        aliquots: [{ id: '1', request: { id: '1', submission: { id: '1', name:'Subm 1' }}}],
        requests_as_source: []
      },
      {
        id: '2',
        position: { name: 'A2' },
        aliquots: [{ id: '2', request: { id: '2', submission: { id: '1', name:'Subm 1' }}}],
        requests_as_source: []
      },
      {
        id: '3',
        position: { name: 'A3' },
        aliquots: [{ id: '3', request: { id: '3', submission: { id: '1', name:'Subm 1' }}}],
        requests_as_source: []
      },
      {
        id: '4',
        position: { name: 'A4' },
        aliquots: [{ id: '4', request: { id: '4', submission: { id: '1', name:'Subm 1' }}}],
        requests_as_source: []
      }
    ]
  }
  const goodParentPlateWithPools = {
    uuid: plateUuid,
    name: 'Test Plate 123456',
    labware_barcode: {
      human_barcode: 'DN123456D'
    },
    state: 'passed',
    number_of_rows: 8,
    number_of_columns: 12,
    wells: [
      {
        id: '1',
        position: { name: 'A1' },
        aliquots: [{ id: '1', request: { id: '1', submission: { id: '1', name:'Subm 1' }}}],
        requests_as_source: [{ id: '1', submission: { id: '1', name:'Subm 1' }}]
      },
      {
        id: '2',
        position: { name: 'A2' },
        aliquots: [{ id: '2', request: { id: '2', submission: { id: '2', name:'Subm 2' }}}],
        requests_as_source: [{ id: '2', submission: { id: '2', name:'Subm 2' }}]
      },
      {
        id: '3',
        position: { name: 'A3' },
        aliquots: [{ id: '3', request: { id: '3', submission: { id: '2', name:'Subm 2' }}}],
        requests_as_source: [{ id: '3', submission: { id: '2', name:'Subm 2' }}]
      },
      {
        id: '4',
        position: { name: 'A4' },
        aliquots: [{ id: '4', request: { id: '4', submission: { id: '2', name:'Subm 2' }}}],
        requests_as_source: [{ id: '4', submission: { id: '2', name:'Subm 2' }}]
      }

    ]
  }
  const goodParentPlateSequential = {
    id: '1',
    uuid: plateUuid,
    name: 'Test Plate 123456',
    labware_barcode: { human_barcode: 'DN123456D' },
    state: 'passed',
    number_of_rows: 8,
    number_of_columns: 12,
    wells: [
      {
        id: '1',
        position: { name: 'A1' },
        aliquots: [{ id: '1', request: { id: '1', submission: { id: '1', name:'Subm 1' }}}],
        requests_as_source: [{ id: '1', submission: { id: '1', name:'Subm 1' }}]
      },
      {
        id: '2',
        position: { name: 'A2' },
        aliquots: [],
        requests_as_source: []
      },
      {
        id: '3',
        position: { name: 'A3' },
        aliquots: [{ id: '3', request: { id: '3', submission: { id: '1', name:'Subm 1' }}}],
        requests_as_source: [{ id: '3', submission: { id: '1', name:'Subm 1' }}]
      },
      {
        id: '4',
        position: { name: 'A4' },
        aliquots: [{ id: '4', request: { id: '4', submission: { id: '1', name:'Subm 1' }}}],
        requests_as_source: [{ id: '4', submission: { id: '1', name:'Subm 1' }}]
      }
    ]
  }
  const goodTagGroupsList = {
    1: {
      id: '1',
      name: 'Tag Group 1',
      tags: [
        { index: 1, oligo: 'CTAGCTAG' },
        { index: 2, oligo: 'TTATACGA' },
        { index: 3, oligo: 'GTATACGA' },
        { index: 4, oligo: 'ATATACGA' },
        { index: 5, oligo: 'GGATACGA' },
        { index: 6, oligo: 'AGATACGA' }
      ]
    },
    2: {
      id: '2',
      name: 'Tag Group 2',
      tags: [
        { index: 1, oligo: 'CCTTAAGG' },
        { index: 2, oligo: 'AATTCGCA' },
        { index: 3, oligo: 'GGTTCGCA' },
        { index: 4, oligo: 'TTTTCGCA' },
        { index: 5, oligo: 'GCTTCGCA' }
      ]
    }
  }
  const goodChildWells = {
    A1: {
      position: 'A1',
      aliquotCount: 1,
      tagIndex: '1',
      poolIndex: 1
    },
    A2: {
      position: 'A2',
      aliquotCount: 1,
      tagIndex: '2',
      poolIndex: 1
    },
    A3: {
      position: 'A3',
      aliquotCount: 1,
      tagIndex: '3',
      poolIndex: 1
    },
    A4: {
      position: 'A4',
      aliquotCount: 1,
      tagIndex: '4',
      poolIndex: 1
    }
  }

  const wrapperFactory = function() {
    return shallowMount(CustomTaggedPlate, {
      propsData: {
        sequencescapeApi: 'http://localhost:3000/api/v2',
        purposeUuid: '',
        targetUrl: '',
        parentUuid: plateUuid
      },
      localVue
    })
  }

  describe("#computed:", () => {
    describe("numberOfRows:", () => {
      it('returns null by default', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.numberOfRows).toEqual(undefined)
      })

      it('returns number of rows on parent plate', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ parentPlate: goodParentPlate })

        expect(wrapper.vm.numberOfRows).toEqual(8)
      })
    })

    describe("numberOfColumns:", () => {
      it('returns null by default', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.numberOfColumns).toEqual(undefined)
      })

      it('returns number of columns on parent plate', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ parentPlate: goodParentPlate })

        expect(wrapper.vm.numberOfColumns).toEqual(12)
      })
    })

    describe("parentWells:", () => {
      it('returns empty object by default', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.parentWells).toEqual({})
      })

      it('returns wells from parent with pool indexes using requests as source', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ parentPlate: goodParentPlate })

        expect(Object.keys(wrapper.vm.parentWells).length).toBe(4)
        expect(wrapper.vm.parentWells.A1.poolIndex).toBe(1)
        expect(wrapper.vm.parentWells.A2.poolIndex).toBe(1)
        expect(wrapper.vm.parentWells.A3.poolIndex).toBe(1)
        expect(wrapper.vm.parentWells.A4.poolIndex).toBe(1)
      })

      it('returns wells from parent with pool indexes using aliquot requests', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ parentPlate: goodParentPlateWithoutWellRequestsAsResource })

        expect(Object.keys(wrapper.vm.parentWells).length).toBe(4)
        expect(wrapper.vm.parentWells.A1.poolIndex).toBe(1)
        expect(wrapper.vm.parentWells.A2.poolIndex).toBe(1)
        expect(wrapper.vm.parentWells.A3.poolIndex).toBe(1)
        expect(wrapper.vm.parentWells.A4.poolIndex).toBe(1)
      })

      it('returns wells from parent with pool indexes where multiple submissions set', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ parentPlate: goodParentPlateWithPools })

        expect(Object.keys(wrapper.vm.parentWells).length).toBe(4)
        expect(wrapper.vm.parentWells.A1.poolIndex).toBe(1)
        expect(wrapper.vm.parentWells.A2.poolIndex).toBe(2)
        expect(wrapper.vm.parentWells.A3.poolIndex).toBe(2)
        expect(wrapper.vm.parentWells.A4.poolIndex).toBe(2)
      })
    })

    describe("childWells:", () => {
      it('returns empty object if parent wells does not exist', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.childWells).toEqual({})
      })

      it('returns parent wells if tag group list is not set', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ parentPlate: goodParentPlate})

        expect(wrapper.vm.childWells).toEqual(wrapper.vm.parentWells)
      })

      it('returns valid wells object if all properties valid', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          parentPlate: goodParentPlate,
          tagGroupsList: goodTagGroupsList,
          tag1GroupId: 1,
          walkingBy: 'by_plate_seq',
          direction: 'by_columns',
          startAtTagNumber: 0
        })

        expect(wrapper.vm.childWells).toEqual(goodChildWells)
      })
    })

    describe("tag1GroupOptions:", () => {
      it('returns empty array if tag groups list empty', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.tag1GroupOptions).toEqual([])
      })

      it('returns valid array if tag groups list set', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ tagGroupsList: goodTagGroupsList })
        const goodTag1GroupOptions = [
          { value: null, text: 'Please select an i7 Tag 1 group...' },
          { value: '1', text: 'Tag Group 1' },
          { value: '2', text: 'Tag Group 2' }
        ]

        expect(wrapper.vm.tag1GroupOptions).toEqual(goodTag1GroupOptions)
      })
    })

    describe("tag2GroupOptions:", () => {
      it('returns empty array if tag groups list empty', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.tag2GroupOptions).toEqual([])
      })

      it('returns valid array if tag groups list set', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ tagGroupsList: goodTagGroupsList })

        const goodTag2GroupOptions = [
          { value: null, text: 'Please select an i5 Tag 2 group...' },
          { value: '1', text: 'Tag Group 1' },
          { value: '2', text: 'Tag Group 2' }
        ]

        expect(wrapper.vm.tag2GroupOptions).toEqual(goodTag2GroupOptions)
      })
    })

    describe("buttonText:", () => {
      it('returns the correct text depending on state', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ state: 'valid' })

        expect(wrapper.vm.buttonText).toEqual('Create new Custom Tagged Plate in Sequencescape')
      })
    })

    describe("buttonStyle:", () => {
      it('returns the correct style depending on state', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ state: 'valid' })

        expect(wrapper.vm.buttonStyle).toEqual('primary')
      })
    })

    describe("buttonDisabled:", () => {
      it('disables the submit button depending on state', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ state: 'valid' })

        expect(wrapper.vm.buttonDisabled).toBe(false)
      })
    })

    describe("numberOfTags:", () => {
      it('returns zero if the tag group list is not set', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.numberOfTags).toBe(0)
      })

      it('returns zero if no tag group has been selected', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ tagGroupsList: goodTagGroupsList })

        expect(wrapper.vm.numberOfTags).toBe(0)
      })

      it('returns the correct number if a tag 1 group has been selected', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          tagGroupsList: goodTagGroupsList,
          tag1GroupId: 1
        })

        expect(wrapper.vm.numberOfTags).toBe(6)
      })

      it('returns the correct cnumber if only tag 2 group has been selected', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          tagGroupsList: goodTagGroupsList,
          tag2GroupId: 2
        })

        expect(wrapper.vm.numberOfTags).toBe(5)
      })
    })

    describe("numberOfTargetWells:", () => {
      it('returns zero if no parent plate exists', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ walkingBy: 'by_plate_seq' })

        expect(wrapper.vm.numberOfTargetWells).toBe(0)
      })

      it('returns zero if no walking by is set', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ parentPlate: goodParentPlate })

        expect(wrapper.vm.numberOfTargetWells).toBe(0)
      })

      it('returns correct value for a fixed plate', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          parentPlate: goodParentPlate,
          walkingBy: 'by_plate_fixed'
        })

        expect(wrapper.vm.numberOfTargetWells).toBe(4)
      })

      it('returns correct value for a plate by sequence', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          parentPlate: goodParentPlateSequential,
          walkingBy: 'by_plate_seq'
        })

        expect(wrapper.vm.numberOfTargetWells).toBe(3)
      })

      it('returns correct value for a plate with pools', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          parentPlate: goodParentPlateWithPools,
          walkingBy: 'by_pool'
        })

        expect(wrapper.vm.numberOfTargetWells).toBe(3)
      })
    })
  })

  // describe("#rendering tests:", () => {
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
  // })

  describe("#integration tests:", () => {
    // it('disables creation if there are no source plate sample wells', () => {

    // it('sets the tag groups if a valid plate is scanned'), () => {

    // it('disables the tag plate scan box if a tag group is chosen'), () => {

    // it('substitutes tags based on selections', () => {

    // it('enables creation if valid tags are chosen', () => {

    // it('disables creation if tag clashes are disabled', () => {

    // it('sends a post request when the create plate button is clicked', async () => {
    //   let mock = new MockAdapter(localVue.prototype.$axios)

    //   // const plate = { state: 'valid', plate: plateFactory({ uuid: 'plate-uuid', _filledWells: 1 }) }

    //   const wrapper = wrapperFactory()

    //   wrapper.setData({
    //     key: 'value',
    //     key: 'value',
    //     key: 'value',
    //     key: 'value',
    //     key: 'value',
    //   })

    //   const expectedPayload = {
    //     plate: {
    //       purpose_uuid: 'test',
    //       parent_uuid: 'plate-uuid',
    //       user_uuid: 'user-uuid',
    //       tag_plate_barcode: 'TG12345678',
    //       tag_plate: {
    //         asset_uuid: 'tag-plate-uuid',
    //         template_uuid: 'tag-template-uuid',
    //         state: 'tag-plate-state'
    //       },
    //       tag_layout: {
    //         user: 'user-uuid',
    //         tag_group: 'tag-group-uuid',
    //         tag2_group: 'tag2-group-uuid',
    //         direction: 'column',
    //         walking_by: 'manual by plate',
    //         initial_tag: '1',
    //         substitutions: {},
    //         tags_per_well: 1
    //       }
    //     }
    //   }

    //   mockLocation.href = null
    //   mock.onPost().reply((config) =>{
    //     expect(config.url).toEqual('example/example')
    //     expect(config.data).toEqual(JSON.stringify(expectedPayload))
    //     return [201, { redirect: 'http://wwww.example.com', message: 'Creating...' }]
    //   })

    //   //  wrapper.vm.createPlate()
    //   wrapper.find('#custom_tagged_plate_submit_button').trigger('click')

    //   await flushPromises()

    //   expect(mockLocation.href).toEqual('http://wwww.example.com')
    // })


  })
})
