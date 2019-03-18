// Import the component being tested
import { mount, shallowMount } from '@vue/test-utils'
import CustomTaggedPlate from './CustomTaggedPlate.vue'
import localVue from 'test_support/base_vue.js'
import MockAdapter from 'axios-mock-adapter'
import flushPromises from 'flush-promises'

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
  const goodTag1Group = {
    id: '1',
    uuid: 'tag-1-group-uuid',
    name: 'Tag Group 1',
    tags: [
      { index: 1, oligo: 'CTAGCTAG' },
      { index: 2, oligo: 'TTATACGA' },
      { index: 3, oligo: 'GTATACGA' },
      { index: 4, oligo: 'ATATACGA' },
      { index: 5, oligo: 'GGATACGA' },
      { index: 6, oligo: 'AGATACGA' }
    ]
  }
  const goodTag2Group = {
    id: '2',
    uuid: 'tag-2-group-uuid',
    name: 'Tag Group 2',
    tags: [
      { index: 1, oligo: 'CCTTAAGG' },
      { index: 2, oligo: 'AATTCGCA' },
      { index: 3, oligo: 'GGTTCGCA' },
      { index: 4, oligo: 'TTTTCGCA' },
      { index: 5, oligo: 'GCTTCGCA' }
    ]
  }
  const goodChildWells = {
    A1: {
      position: 'A1',
      aliquotCount: 1,
      tagIndex: '1',
      pool_index: 1,
      validity: { valid: true, message: '' }
    },
    A2: {
      position: 'A2',
      aliquotCount: 1,
      tagIndex: '2',
      pool_index: 1,
      validity: { valid: true, message: '' }
    },
    A3: {
      position: 'A3',
      aliquotCount: 1,
      tagIndex: '3',
      pool_index: 1,
      validity: { valid: true, message: '' }
    },
    A4: {
      position: 'A4',
      aliquotCount: 1,
      tagIndex: '4',
      pool_index: 1,
      validity: { valid: true, message: '' }
    }
  }
  const goodQcableData = {
    plate: {
      id:'1',
      uuid: 'tag-plate-uuid',
      state:'available',
      labware_barcode: {
        human_barcode: 'TG12345678'
      },
      lot:{
        id:'1',
        tag_layout_template:{
          id:'1',
          uuid: 'tag-template-uuid',
          direction:'row',
          walking_by:'wells of plate',
          tag_group:{
            id:'1',
            name:'i7 example tag group 1',
          },
          tag2_group:{
            id:'2',
            name:'i5 example tag group 2',
          }
        }
      }
    },
    state: 'valid'
  }

  const goodTagClashes = { 1: { wells: [], subsmission: true }, 4: { wells: [ 5 ], submission: false } }

  const mockLocation = {}
  const wrapperFactory = function() {
    return shallowMount(CustomTaggedPlate, {
      propsData: {
        sequencescapeApi: 'http://localhost:3000/api/v2',
        purposeUuid: '',
        targetUrl: '',
        parentUuid: plateUuid,
        tagsPerWell: '1',
        locationObj: mockLocation
      },
      localVue
    })
  }

  describe('#computed:', () => {
    describe('tagsValid:', () => {
      it('returns false if no childWells', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.tagsValid).toEqual(false)
      })

      it('returns false if there are any tag clashes', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ tagClashes: goodTagClashes })

        expect(wrapper.vm.tagsValid).toEqual(false)
      })

      it('returns false if any wells with aliquots do not contain a tag', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          tagClashes: {},
          parentPlate: goodParentPlate,
          tag1Group: goodTag1Group,
          walkingBy: 'manual by plate',
          direction: 'column',
          offsetTagsBy: 4
        })

        expect(wrapper.vm.tagsValid).toEqual(false)
      })

      it('returns true if all aliquots contain valid tag indexes', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          tagClashes: {},
          parentPlate: goodParentPlate,
          tag1Group: goodTag1Group,
          walkingBy: 'manual by plate',
          direction: 'column'
        })

        expect(wrapper.vm.tagsValid).toEqual(true)
      })
    })

    describe('createButtonState:', () => {
      it('returns setup if tags are not valid', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          loading: true,
          tagClashes: {},
          parentPlate: goodParentPlate,
          tag1Group: goodTag1Group,
          walkingBy: 'manual by plate',
          direction: 'column',
          offsetTagsBy: 4
        })

        expect(wrapper.vm.createButtonState).toEqual('setup')
      })

      it('returns pending if tags are valid and creation not started', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          loading: false,
          tagClashes: {},
          parentPlate: goodParentPlate,
          tag1Group: goodTag1Group,
          walkingBy: 'manual by plate',
          direction: 'column'
        })

        expect(wrapper.vm.createButtonState).toEqual('pending')
      })

      it('returns busy if tags are valid and creation in progress', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          loading: true,
          tagClashes: {},
          parentPlate: goodParentPlate,
          tag1Group: goodTag1Group,
          walkingBy: 'manual by plate',
          direction: 'column',
          creationRequestInProgress: true
        })

        expect(wrapper.vm.createButtonState).toEqual('busy')
      })

      it('returns success if creation was successful', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          loading: false,
          tagClashes: {},
          parentPlate: goodParentPlate,
          tag1Group: goodTag1Group,
          walkingBy: 'manual by plate',
          direction: 'column',
          creationRequestInProgress: false,
          creationRequestSuccessful: true
        })

        expect(wrapper.vm.createButtonState).toEqual('success')
      })

      it('returns failure if creation was unsuccessful', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          loading: false,
          tagClashes: {},
          parentPlate: goodParentPlate,
          tag1Group: goodTag1Group,
          walkingBy: 'manual by plate',
          direction: 'column',
          creationRequestInProgress: false,
          creationRequestSuccessful: false
        })

        expect(wrapper.vm.createButtonState).toEqual('failure')
      })
    })

    describe('numberOfRows:', () => {
      it('returns null rows by default', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.numberOfRows).toEqual(null)
      })

      it('returns number of rows on parent plate', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ parentPlate: goodParentPlate })

        expect(wrapper.vm.numberOfRows).toEqual(8)
      })
    })

    describe('numberOfColumns:', () => {
      it('returns null columns by default', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.numberOfColumns).toEqual(null)
      })

      it('returns number of columns on parent plate', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ parentPlate: goodParentPlate })

        expect(wrapper.vm.numberOfColumns).toEqual(12)
      })
    })

    describe('tagsPerWellAsNumber:', () => {
      it('returns a numeric version of the prop tags per well', () => {
        const wrapper = wrapperFactory()

        wrapper.setProps({ tagsPerWell: '4' })

        expect(wrapper.vm.tagsPerWellAsNumber).toEqual(4)
      })
    })

    describe('parentWells:', () => {
      it('returns empty object by default', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.parentWells).toEqual({})
      })

      it('returns wells from parent with pool indexes using requests as source', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ parentPlate: goodParentPlate })

        expect(Object.keys(wrapper.vm.parentWells).length).toBe(4)
        expect(wrapper.vm.parentWells.A1.pool_index).toBe(1)
        expect(wrapper.vm.parentWells.A2.pool_index).toBe(1)
        expect(wrapper.vm.parentWells.A3.pool_index).toBe(1)
        expect(wrapper.vm.parentWells.A4.pool_index).toBe(1)
      })

      it('returns wells from parent with pool indexes using aliquot requests', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ parentPlate: goodParentPlateWithoutWellRequestsAsResource })

        expect(Object.keys(wrapper.vm.parentWells).length).toBe(4)
        expect(wrapper.vm.parentWells.A1.pool_index).toBe(1)
        expect(wrapper.vm.parentWells.A2.pool_index).toBe(1)
        expect(wrapper.vm.parentWells.A3.pool_index).toBe(1)
        expect(wrapper.vm.parentWells.A4.pool_index).toBe(1)
      })

      it('returns wells from parent with pool indexes where multiple submissions set', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ parentPlate: goodParentPlateWithPools })

        expect(Object.keys(wrapper.vm.parentWells).length).toBe(4)
        expect(wrapper.vm.parentWells.A1.pool_index).toBe(1)
        expect(wrapper.vm.parentWells.A2.pool_index).toBe(2)
        expect(wrapper.vm.parentWells.A3.pool_index).toBe(2)
        expect(wrapper.vm.parentWells.A4.pool_index).toBe(2)
      })
    })

    describe('childWells:', () => {
      it('returns empty object if parent wells does not exist', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.childWells).toEqual({})
      })

      it('returns parent wells if no tag layout', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ parentPlate: goodParentPlate})

        expect(wrapper.vm.childWells).toEqual(wrapper.vm.parentWells)
      })

      it('returns valid wells object if all properties valid', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          parentPlate: goodParentPlate,
          tag1Group: goodTag1Group,
          walkingBy: 'manual by plate',
          direction: 'column'
        })

        expect(wrapper.vm.childWells).toEqual(goodChildWells)
      })
    })

    describe('button text, style and disabled:', () => {
      it('returns the correct text depending on state', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          tagClashes: {},
          parentPlate: goodParentPlate,
          tag1Group: goodTag1Group,
          walkingBy: 'manual by plate',
          direction: 'column'
        })

        expect(wrapper.vm.createButtonState).toEqual('pending')
        expect(wrapper.vm.buttonText).toEqual('Create new Custom Tagged plate in Sequencescape')
        expect(wrapper.vm.buttonStyle).toEqual('primary')
        expect(wrapper.vm.buttonDisabled).toBe(false)
      })
    })

    describe('numberOfTags:', () => {
      it('returns zero if no tag group has been selected', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.numberOfTags).toBe(0)
      })

      it('returns the correct number if a tag 1 group has been selected', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          tag1Group: goodTag1Group
        })

        expect(wrapper.vm.numberOfTags).toBe(6)
      })

      it('returns the correct cnumber if only tag 2 group has been selected', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          tag2Group: goodTag2Group
        })

        expect(wrapper.vm.numberOfTags).toBe(5)
      })
    })

    describe('numberOfTargetWells:', () => {
      it('returns zero if no parent plate exists', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ walkingBy: 'manual by plate' })

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
          walkingBy: 'wells of plate'
        })

        expect(wrapper.vm.numberOfTargetWells).toBe(4)
      })

      it('returns correct value for a plate by sequence', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          parentPlate: goodParentPlateSequential,
          walkingBy: 'manual by plate'
        })

        expect(wrapper.vm.numberOfTargetWells).toBe(3)
      })

      it('returns correct value for a plate with pools', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          parentPlate: goodParentPlateWithPools,
          walkingBy: 'manual by pool'
        })

        expect(wrapper.vm.numberOfTargetWells).toBe(3)
      })
    })
  })

  describe('#rendering tests:', () => {
    it('renders a vue instance', () => {
      const wrapper = wrapperFactory()

      expect(wrapper.isVueInstance()).toBe(true)
    })

    it('renders child components', async () => {
      const wrapper = mount(CustomTaggedPlate, {
        propsData: {
          sequencescapeApi: 'http://localhost:3000/api/v2',
          purposeUuid: '',
          targetUrl: '',
          parentUuid: plateUuid,
          tagsPerWell: '1',
          locationObj: mockLocation
        },
        stubs: {
          'lb-parent-plate-view': '<table class="plate-view"></table>',
          'lb-custom-tagged-plate-manipulation': '<fieldset class="b-form-group"></fieldset>'
        },
        localVue
      })

      wrapper.setData({
        parentPlate: goodParentPlate
      })

      expect(wrapper.find('table.plate-view').exists()).toBe(true)
      expect(wrapper.find('fieldset.b-form-group').exists()).toBe(true)
    })

    it('renders a submit button', async () => {
      const wrapper = wrapperFactory()

      await flushPromises()

      expect(wrapper.find('#custom_tagged_plate_submit_button').exists()).toBe(true)
    })
  })

  describe('#integration tests:', () => {
    // it('disables creation if there are no source plate sample wells', () => {

    // it('sets the tag groups if a valid plate is scanned'), () => {

    // it('disables the tag plate scan box if a tag group is chosen'), () => {

    // it('substitutes tags based on selections', () => {

    // it('enables creation if valid tags are chosen', () => {

    // it('disables creation if tag clashes are disabled', () => {

    it('sends a post request when the create plate button is clicked', async () => {
      let mock = new MockAdapter(localVue.prototype.$axios)

      const wrapper = wrapperFactory()

      wrapper.setProps({
        purposeUuid: 'purpose-uuid',
        targetUrl: 'example/example',
        parentUuid: 'parent-plate-uuid',
        tagsPerWell: '1'
      })

      wrapper.setData({
        tagPlate: goodQcableData.plate,
        tag1Group: goodTag1Group,
        tag2Group: goodTag2Group,
        direction: 'column',
        walkingBy: 'manual by plate',
        offsetTagsBy: 1,
        tagSubstitutions: {}
      })

      const expectedPayload = {
        plate: {
          purpose_uuid: 'purpose-uuid',
          parent_uuid: 'parent-plate-uuid',
          tag_layout: {
            tag_group: 'tag-1-group-uuid',
            tag2_group: 'tag-2-group-uuid',
            direction: 'column',
            walking_by: 'manual by plate',
            initial_tag: 1,
            substitutions: {},
            tags_per_well: 1
          },
          tag_plate: {
            asset_uuid: 'tag-plate-uuid',
            template_uuid: 'tag-template-uuid',
            state: 'available'
          }
        }
      }

      mockLocation.href = null
      mock.onPost().reply((config) =>{
        expect(config.url).toEqual('example/example')
        expect(config.data).toEqual(JSON.stringify(expectedPayload))
        return [201, { redirect: 'http://wwww.example.com', message: 'Creating...' }]
      })

      // to click the button we would need to mount rather than shallowMount, but then we run into issues with mocking other database calls
      wrapper.vm.createPlate()

      await flushPromises()

      expect(mockLocation.href).toEqual('http://wwww.example.com')
    })
  })
})
