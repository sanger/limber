// Import the component being tested
import { shallowMount } from '@vue/test-utils'
import CustomTaggedPlate from './CustomTaggedPlate.vue'
import localVue from 'test_support/base_vue.js'
import { jsonCollectionFactory } from 'test_support/factories'
import flushPromises from 'flush-promises'
import mockApi from 'test_support/mock_api'

describe('CustomTaggedPlate', () => {
  const plateUuid = 'afabla7e-9498-42d6-964e-50f61ded6d9a'
  const nullPlate = { data: [] }
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

  const wrapperFactory = function(api = mockApi()) {
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

  // test computed properties
  it('returns null for computed number of rows by default', () => {
    const wrapper = wrapperFactory()

    expect(wrapper.vm.numberOfRows).toEqual(undefined)
  })

  it('returns number of rows from plate once parent plate has been set', () => {
    const wrapper = wrapperFactory()

    wrapper.setData({ parentPlate: goodParentPlate })
    expect(wrapper.vm.numberOfRows).toEqual(8)
  })

  it('returns null for computed number of columns by default', () => {
    const wrapper = wrapperFactory()

    expect(wrapper.vm.numberOfColumns).toEqual(undefined)
  })

  it('returns number of columns from plate once parent plate has been set', () => {
    const wrapper = wrapperFactory()

    wrapper.setData({ parentPlate: goodParentPlate })
    expect(wrapper.vm.numberOfColumns).toEqual(12)
  })

  it('returns empty object for computed parent wells by default', () => {
    const wrapper = wrapperFactory()

    expect(wrapper.vm.parentWells).toEqual({})
  })

  it('returns wells from plate with pool indexes once parent plate has been set', () => {
    const wrapper = wrapperFactory()

    wrapper.setData({ parentPlate: goodParentPlate })
    expect(Object.keys(wrapper.vm.parentWells).length).toBe(4)
    expect(wrapper.vm.parentWells.A1.poolIndex).toBe(1)
    expect(wrapper.vm.parentWells.A2.poolIndex).toBe(1)
    expect(wrapper.vm.parentWells.A3.poolIndex).toBe(1)
    expect(wrapper.vm.parentWells.A4.poolIndex).toBe(1)
  })

  it('sets well pool indexes when wells have aliquot requests but not requests as source', () => {
    const wrapper = wrapperFactory()

    wrapper.setData({ parentPlate: goodParentPlateWithoutWellRequestsAsResource })
    expect(Object.keys(wrapper.vm.parentWells).length).toBe(4)
    expect(wrapper.vm.parentWells.A1.poolIndex).toBe(1)
    expect(wrapper.vm.parentWells.A2.poolIndex).toBe(1)
    expect(wrapper.vm.parentWells.A3.poolIndex).toBe(1)
    expect(wrapper.vm.parentWells.A4.poolIndex).toBe(1)
  })

  it('sets different well pool indexes if parent plate has multiple submissions set', () => {
    const wrapper = wrapperFactory()

    wrapper.setData({ parentPlate: goodParentPlateWithPools })
    expect(Object.keys(wrapper.vm.parentWells).length).toBe(4)
    expect(wrapper.vm.parentWells.A1.poolIndex).toBe(1)
    expect(wrapper.vm.parentWells.A2.poolIndex).toBe(2)
    expect(wrapper.vm.parentWells.A3.poolIndex).toBe(2)
    expect(wrapper.vm.parentWells.A4.poolIndex).toBe(2)
  })

  it('returns empty object for computed childWells if parent wells does not exist', () => {
    const wrapper = wrapperFactory()

    expect(wrapper.vm.childWells).toEqual({})
  })

  it('returns parent wells for computed childWells if tag group list is not set', () => {
    const wrapper = wrapperFactory()

    wrapper.setData({ parentPlate: goodParentPlate})

    expect(wrapper.vm.childWells).toEqual(wrapper.vm.parentWells)
  })

  it('returns valid wells object for computed childWells if all properties valid', () => {
    const wrapper = wrapperFactory()

    wrapper.setData({ parentPlate: goodParentPlate })
    wrapper.setData({ tagGroupsList: goodTagGroupsList })
    wrapper.setData({ tag1GroupId: 1 })
    wrapper.setData({ walkingBy: 'by_plate_seq' })
    wrapper.setData({ direction: 'by_columns' })
    wrapper.setData({ startAtTagNumber: 0 })
    expect(wrapper.vm.childWells).toEqual(goodChildWells)
  })

  it('returns empty object for computed tag 1 group options if tag groups list empty', () => {
    const wrapper = wrapperFactory()

    expect(wrapper.vm.tag1GroupOptions).toEqual([])
  })

  it('returns valid list for computed tag 1 group options if tag groups list set', () => {
    const wrapper = wrapperFactory()

    wrapper.setData({ tagGroupsList: goodTagGroupsList })
    const goodTag1GroupOptions = [
      { value: null, text: 'Please select an i7 Tag 1 group...' },
      { value: '1', text: 'Tag Group 1' },
      { value: '2', text: 'Tag Group 2' }
    ]
    expect(wrapper.vm.tag1GroupOptions).toEqual(goodTag1GroupOptions)
  })

  it('returns empty object for computed tag 2 group options if tag groups list empty', () => {
    const wrapper = wrapperFactory()

    expect(wrapper.vm.tag2GroupOptions).toEqual([])
  })

  it('returns valid list for computed tag 2 group options if tag groups list set', () => {
    const wrapper = wrapperFactory()

    wrapper.setData({ tagGroupsList: goodTagGroupsList })

    const goodTag2GroupOptions = [
      { value: null, text: 'Please select an i5 Tag 2 group...' },
      { value: '1', text: 'Tag Group 1' },
      { value: '2', text: 'Tag Group 2' }
    ]

    expect(wrapper.vm.tag2GroupOptions).toEqual(goodTag2GroupOptions)
  })

  it('returns the correct button text depending on state', () => {
    const wrapper = wrapperFactory()

    wrapper.setData({ state: 'valid' })

    expect(wrapper.vm.buttonText).toEqual('Create new Custom Tagged Plate in Sequencescape')
  })

  it('returns the correct button style depending on state', () => {
    const wrapper = wrapperFactory()

    wrapper.setData({ state: 'valid' })

    expect(wrapper.vm.buttonStyle).toEqual('primary')
  })

  it('returns the correct button text depending on state', () => {
    const wrapper = wrapperFactory()

    wrapper.setData({ state: 'valid' })

    expect(wrapper.vm.disabled).toBe(false)
  })

  it('returns zero for the computed number of tags if the tag group list is not set', () => {
    const wrapper = wrapperFactory()

    expect(wrapper.vm.numberOfTags).toBe(0)
  })

  it('returns zero for the computed number of tags if no tag group has been selected', () => {
    const wrapper = wrapperFactory()

    wrapper.setData({ tagGroupsList: goodTagGroupsList })

    expect(wrapper.vm.numberOfTags).toBe(0)
  })

  it('returns the correct computed number of tags if a tag 1 group has been selected', () => {
    const wrapper = wrapperFactory()

    wrapper.setData({ tagGroupsList: goodTagGroupsList })
    wrapper.setData({ tag1GroupId: 1 })

    expect(wrapper.vm.numberOfTags).toBe(6)
  })

  it('returns the correct computed number of tags if only tag 2 group has been selected', () => {
    const wrapper = wrapperFactory()

    wrapper.setData({ tagGroupsList: goodTagGroupsList })
    wrapper.setData({ tag2GroupId: 2 })

    expect(wrapper.vm.numberOfTags).toBe(5)
  })

  it('returns zero for the computed number of target wells if no parent plate exists', () => {
    const wrapper = wrapperFactory()

    wrapper.setData({ walkingBy: 'by_plate_seq' })

    expect(wrapper.vm.numberOfTargetWells).toBe(0)
  })

  it('returns zero for the computed number of target wells if no walking by is set', () => {
    const wrapper = wrapperFactory()

    wrapper.setData({ parentPlate: goodParentPlate })

    expect(wrapper.vm.numberOfTargetWells).toBe(0)
  })

  it('returns correct value for the computed number of target wells for a fixed plate', () => {
    const wrapper = wrapperFactory()

    wrapper.setData({ parentPlate: goodParentPlate })
    wrapper.setData({ walkingBy: 'by_plate_fixed' })

    expect(wrapper.vm.numberOfTargetWells).toBe(4)
  })

  it('returns correct value for the computed number of target wells for a plate by sequence', () => {
    const wrapper = wrapperFactory()

    wrapper.setData({ parentPlate: goodParentPlateSequential })
    wrapper.setData({ walkingBy: 'by_plate_seq' })

    expect(wrapper.vm.numberOfTargetWells).toBe(3)
  })

  it('returns correct value for the computed number of target wells for a plate with pools', () => {
    const wrapper = wrapperFactory()

    wrapper.setData({ parentPlate: goodParentPlateWithPools })
    wrapper.setData({ walkingBy: 'by_pool' })

    expect(wrapper.vm.numberOfTargetWells).toBe(3)
  })

  // it('returns ?', () => {
  //   const wrapper = wrapperFactory()
  //   wrapper.setData({ dataName: "input value" })
  //   expect(wrapper.vm.computedName).toBe("result value")
  // })

  // it('returns differently ? if prop is set', () => {
  //   const wrapper = wrapperFactory()
  //   wrapper.setData({ dataName: "input value" })
  //   wrapper.setProps({ propName: true })
  //   expect(wrapper.vm.computedName).toBe("result value 2")
  // })

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
