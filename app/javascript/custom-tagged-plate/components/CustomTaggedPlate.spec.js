// Import the component being tested
import { mount, shallowMount } from '@vue/test-utils'
import CustomTaggedPlate from './CustomTaggedPlate.vue'
import localVue from 'test_support/base_vue.js'
import MockAdapter from 'axios-mock-adapter'
import flushPromises from 'flush-promises'
import {
  plateUuid,
  exampleParent,
  exampleParentTag1Only,
  exampleParentWithoutWellRequestsAsResource,
  exampleParentSequential,
  exampleParentWithPools,
  exampleTag1Group,
  exampleTag2Group,
  exampleTag2GroupLonger,
  exampleChildWells,
  exampleQcableData
} from '../testData/tagClashFunctionsTestData.js'

describe('CustomTaggedPlate', () => {
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

      it('returns false if any wells with aliquots do not contain a tag', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          parentPlate: exampleParentTag1Only,
          tag1Group: exampleTag1Group,
          walkingBy: 'manual by plate',
          direction: 'column',
          offsetTagsBy: 4
        })

        expect(wrapper.vm.tagsValid).toEqual(false)
      })

      it('returns true if all aliquots contain valid tag indexes', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          parentPlate: exampleParentTag1Only,
          tag1Group: exampleTag1Group,
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
          parentPlate: exampleParentTag1Only,
          tag1Group: exampleTag1Group,
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
          parentPlate: exampleParentTag1Only,
          tag1Group: exampleTag1Group,
          walkingBy: 'manual by plate',
          direction: 'column'
        })

        expect(wrapper.vm.createButtonState).toEqual('pending')
      })

      it('returns busy if tags are valid and creation in progress', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          loading: true,
          parentPlate: exampleParentTag1Only,
          tag1Group: exampleTag1Group,
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
          parentPlate: exampleParentTag1Only,
          tag1Group: exampleTag1Group,
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
          parentPlate: exampleParentTag1Only,
          tag1Group: exampleTag1Group,
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

        wrapper.setData({ parentPlate: exampleParent })

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

        wrapper.setData({ parentPlate: exampleParent })

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

        wrapper.setData({
          parentPlate: exampleParent
        })

        expect(Object.keys(wrapper.vm.parentWells).length).toBe(4)
        expect(wrapper.vm.parentWells.A1.pool_index).toBe(1)
        expect(wrapper.vm.parentWells.A2.pool_index).toBe(1)
        expect(wrapper.vm.parentWells.A3.pool_index).toBe(1)
        expect(wrapper.vm.parentWells.A4.pool_index).toBe(1)
      })

      it('returns wells from parent with pool indexes using aliquot requests', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          parentPlate: exampleParentWithoutWellRequestsAsResource
        })

        expect(Object.keys(wrapper.vm.parentWells).length).toBe(4)
        expect(wrapper.vm.parentWells.A1.pool_index).toBe(1)
        expect(wrapper.vm.parentWells.A2.pool_index).toBe(1)
        expect(wrapper.vm.parentWells.A3.pool_index).toBe(1)
        expect(wrapper.vm.parentWells.A4.pool_index).toBe(1)
      })

      it('returns wells from parent with pool indexes where multiple submissions set', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          parentPlate: exampleParentWithPools
        })

        expect(Object.keys(wrapper.vm.parentWells).length).toBe(4)
        expect(wrapper.vm.parentWells.A1.pool_index).toBe(1)
        expect(wrapper.vm.parentWells.A2.pool_index).toBe(1)
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

        wrapper.setData({ parentPlate: exampleParent})

        expect(wrapper.vm.childWells).toEqual(wrapper.vm.parentWells)
      })

      it('returns valid wells object if all properties valid', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          parentPlate: exampleParentTag1Only,
          tag1Group: exampleTag1Group,
          walkingBy: 'manual by plate',
          direction: 'column'
        })

        expect(wrapper.vm.childWells).toEqual(exampleChildWells)
      })
    })

    describe('button text, style and disabled:', () => {
      it('returns the correct text depending on state', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          parentPlate: exampleParentTag1Only,
          tag1Group: exampleTag1Group,
          walkingBy: 'manual by plate',
          direction: 'column'
        })

        expect(wrapper.vm.createButtonState).toEqual('pending')
        expect(wrapper.vm.buttonText).toEqual('Create new Custom Tagged plate')
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
          tag1Group: exampleTag1Group
        })

        expect(wrapper.vm.numberOfTags).toBe(7)
      })

      it('returns the correct number if only tag 2 group has been selected', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          tag2Group: exampleTag2Group
        })

        expect(wrapper.vm.numberOfTags).toBe(6)
      })

      it('returns the correct number if tag 1 group has more tags than tag 2 group', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          tag1Group: exampleTag1Group,
          tag2Group: exampleTag2Group
        })

        expect(wrapper.vm.numberOfTags).toBe(6)
      })
    })

    describe('useableTagMapIds:', () => {
      it('returns an empty array if no tag groups have been selected', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.useableTagMapIds).toEqual([])
      })

      it('returns an array of the tag 1 group map ids if only tag 1 group is selected', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          tag1Group: exampleTag1Group
        })

        expect(wrapper.vm.useableTagMapIds).toEqual([11,12,13,14,15,16,17])
      })

      it('returns an array of the tag 2 group map ids if only tag 2 group is selected', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          tag2Group: exampleTag2Group
        })

        expect(wrapper.vm.useableTagMapIds).toEqual([21,22,23,24,25,26])
      })

      it('returns a shortened array of the tag 1 group map ids if both groups are selected and tag group 2 is smaller', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          tag1Group: exampleTag1Group,
          tag2Group: exampleTag2Group
        })

        expect(wrapper.vm.useableTagMapIds).toEqual([11,12,13,14,15,16])
      })

      it('returns a full array of the tag 1 group map ids if both groups are selected and tag group 2 is longer', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          tag1Group: exampleTag1Group,
          tag2Group: exampleTag2GroupLonger
        })

        expect(wrapper.vm.useableTagMapIds).toEqual([11,12,13,14,15,16,17])
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

        wrapper.setData({ parentPlate: exampleParent })

        expect(wrapper.vm.numberOfTargetWells).toBe(0)
      })

      it('returns correct value for a fixed plate', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          parentPlate: exampleParent,
          walkingBy: 'wells of plate'
        })

        expect(wrapper.vm.numberOfTargetWells).toBe(4)
      })

      it('returns correct value for a plate by sequence', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          parentPlate: exampleParentSequential,
          walkingBy: 'manual by plate'
        })

        expect(wrapper.vm.numberOfTargetWells).toBe(3)
      })

      it('returns correct value for a plate with pools', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({
          parentPlate: exampleParentWithPools,
          walkingBy: 'manual by pool'
        })

        expect(wrapper.vm.numberOfTargetWells).toBe(2)
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
          'lb-custom-tagged-plate-details': '<div class="plate-details"></div>',
          'lb-custom-tagged-plate-manipulation': '<fieldset class="b-form-group"></fieldset>',
          'lb-well-modal': '<div class="well-modal"></div>'
        },
        localVue
      })

      wrapper.setData({
        parentPlate: exampleParent
      })

      expect(wrapper.find('table.plate-view').exists()).toBe(true)
      expect(wrapper.find('fieldset.b-form-group').exists()).toBe(true)
      expect(wrapper.find('div.plate-details').exists()).toBe(true)
      expect(wrapper.find('div.well-modal').exists()).toBe(true)
    })

    it('renders a submit button', async () => {
      const wrapper = wrapperFactory()

      await flushPromises()

      expect(wrapper.find('#custom_tagged_plate_submit_button').exists()).toBe(true)
    })
  })

  describe('#integration tests:', () => {
    it('disallows tag substitutions for chromium plates', () => {
      const wrapper = wrapperFactory()

      wrapper.setProps({
        tagsPerWell: '4'
      })

      wrapper.setData({
        parentPlate: exampleParent,
        tag1Group: exampleTag1Group,
        tag2Group: exampleTag2Group,
        direction: 'row',
        walkingBy: 'wells of plate'
      })

      expect(wrapper.vm.isChromiumPlate).toBe(true)
      expect(wrapper.vm.tagSubstitutionsAllowed).toBe(false)
    })

    it('sets a childwell to invalid if there is a tag clash with the submission', () => {
      const wrapper = wrapperFactory()

      wrapper.setData({
        parentPlate: exampleParent,
        tag1Group: exampleTag1Group,
        tag2Group: exampleTag2Group,
        direction: 'row',
        walkingBy: 'wells of plate',
        tagSubstitutions: { 14: 15 }
      })

      expect(wrapper.vm.childWells['A4'].validity.valid).toBe(false)
      expect(wrapper.vm.childWells['A4'].validity.message).toBe('Tag clash with the following: submission')
    })

    it('sets a childwell to invalid if there is a tag clash with another childwell', () => {
      const wrapper = wrapperFactory()

      wrapper.setData({
        parentPlate: exampleParent,
        tag1Group: exampleTag1Group,
        tag2Group: exampleTag2Group,
        direction: 'row',
        walkingBy: 'wells of plate',
        tagSubstitutions: { 13: 11 }
      })

      expect(wrapper.vm.childWells['A1'].validity.valid).toBe(false)
      expect(wrapper.vm.childWells['A1'].validity.message).toBe('Tag clash with the following: A3')
      expect(wrapper.vm.childWells['A3'].validity.valid).toBe(false)
      expect(wrapper.vm.childWells['A3'].validity.message).toBe('Tag clash with the following: A1')
    })

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
        tagPlate: exampleQcableData.plate,
        tag1Group: exampleTag1Group,
        tag2Group: exampleTag2Group,
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
