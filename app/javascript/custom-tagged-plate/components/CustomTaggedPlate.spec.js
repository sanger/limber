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
    labware_barcode: {
      human_barcode: 'DN123456D'
    },
    state: 'passed',
    number_of_rows: 8,
    number_of_columns: 12,
    wells: [
      {
        id: '1',
        position: {
          name: 'A1'
        },
        aliquots: [
          {
            id: '1',
            request: {
              id: '1',
              submission: {
                id: '1',
                name:'Test 1 Submission Name',
              },
            },
          }
        ],
        requests_as_source: [
          {
            id: '1',
            submission: {
              id: '1',
              name:'Test 1 Submission Name',
            },
          }
        ]
      },
      {
        id: '2',
        position: {
          name: 'A2'
        },
        aliquots: [
          {
            id: '2',
            request: {
              id: '2',
              submission: {
                id: '1',
                name:'Test 1 Submission Name',
              },
            },
          }
        ],
        requests_as_source: [
          {
            id: '1',
            submission: {
              id: '1',
              name:'Test 1 Submission Name',
            },
          }
        ]
      }
    ],
  }
  const goodParentPlateWithoutWellRequestsAsResource = {
    id: '1',
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
        position: {
          name: 'A1'
        },
        aliquots: [
          {
            id: '1',
            request: {
              id: '1',
              submission: {
                id: '1',
                name:'Test 1 Submission Name',
              },
            },
          }
        ],
        requests_as_source: []
      },
      {
        id: '2',
        position: {
          name: 'A2'
        },
        aliquots: [
          {
            id: '2',
            request: {
              id: '2',
              submission: {
                id: '1',
                name:'Test 1 Submission Name',
              },
            },
          }
        ],
        requests_as_source: []
      }
    ],
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
        position: {
          name: 'A1'
        },
        aliquots: [
          {
            request: {
              submission: {
                id: '1',
                name:'Test 1 Submission Name',
              },
            },
          }
        ],
        requests_as_source: [
          {
            submission: {
              id: '1',
              name:'Test 1 Submission Name',
            },
          }
        ]
      },
      {
        position: {
          name: 'A2'
        },
        aliquots: [
          {
            request: {
              submission: {
                id: '2',
                name:'Test 2 Submission Name',
              },
            },
          }
        ],
        requests_as_source: [
          {
            submission: {
              id: '2',
              name:'Test 2 Submission Name',
            },
          }
        ]
      }
    ]
  }
  const goodTagGroupsList = {
    1: {
      id: '1',
      name: 'Tag Group 1',
      tags: [
        {
          index: 1,
          oligo: 'CTAGCTAG'
        },
        {
          index: 2,
          oligo: 'TTATACGA'
        }
      ]
    },
    2: {
      id: '2',
      name: 'Tag Group 2',
      tags: [
        {
          index: 1,
          oligo: 'CCTTAAGG'
        },
        {
          index: 2,
          oligo: 'AATTCGCA'
        }
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
    }
  }
  // const nullTagGroups = { data: [] }




  // data () {
  //     return {
  //       devourApi: devourApi({ apiUrl: this.sequencescapeApi }, resources),
  //       state: 'searching',
  //       parentPlate: null,
  //       tagGroupsList: null,
  //       progressMessageParent: 'Fetching parent plate details...',
  //       progressMessageTags: 'Fetching tag groups...',
  //       startAtTagMin: 1,
  //       startAtTagMax: 96,
  //       startAtTagStep: 1,
  //       offsetTagsByOptions: {},
  //       errorMessages: [],
  //       form: {
  //         tagPlateBarcode: null,
  //         tag1GroupId: null,
  //         tag2GroupId: null,
  //         byPoolPlateOption: null,
  //         byRowColOption: null,
  //         offsetTagsByOption: 1,
  //         tagsPerWellOption: 1
  //       }
  //     }
  //   },
  //   props: {
  //     sequencescapeApi: { type: String, default: 'http://localhost:3000/api/v2' },
  //     purposeUuid: { type: String, required: true },
  //     targetUrl: { type: String, required: true },
  //     parentUuid: { type: String, required: true }
  //   },

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

  // const wrapperFactoryLoaded = function(api = mockApi()) {
  //   return shallowMount(CustomTaggedPlate, {
  //     propsData: {
  //       sequencescapeApi: 'http://localhost:3000/api/v2',
  //       purposeUuid: '',
  //       targetUrl: '',
  //       parentUuid: ''
  //     },
  //     localVue
  //   })
  // }



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
    expect(Object.keys(wrapper.vm.parentWells).length).toBe(2)
    expect(wrapper.vm.parentWells.A1.poolIndex).toBe(1)
    expect(wrapper.vm.parentWells.A2.poolIndex).toBe(1)
  })

  it('sets well pool indexes when wells have aliquot requests but not requests as source', () => {
    const wrapper = wrapperFactory()

    wrapper.setData({ parentPlate: goodParentPlateWithoutWellRequestsAsResource })
    expect(Object.keys(wrapper.vm.parentWells).length).toBe(2)
    expect(wrapper.vm.parentWells.A1.poolIndex).toBe(1)
    expect(wrapper.vm.parentWells.A2.poolIndex).toBe(1)
  })

  it('sets different well pool indexes if parent plate has multiple submissions set', () => {
    const wrapper = wrapperFactory()

    wrapper.setData({ parentPlate: goodParentPlateWithPools })
    expect(Object.keys(wrapper.vm.parentWells).length).toBe(2)
    expect(wrapper.vm.parentWells.A1.poolIndex).toBe(1)
    expect(wrapper.vm.parentWells.A2.poolIndex).toBe(2)
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
    wrapper.setData({ byPoolPlateOption: 'by_plate_seq' })
    wrapper.setData({ byRowColOption: 'by_columns' })
    wrapper.setData({ offsetTagsByOption: 0 })
    expect(wrapper.vm.childWells).toEqual(goodChildWells)
  })

  // compTag1GroupOptions
  // compTag2GroupOptions
  // coreTagGroupOptions
  // compOffsetTagsByOptions
  // buttonText
  // buttonStyle
  // disabled

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
