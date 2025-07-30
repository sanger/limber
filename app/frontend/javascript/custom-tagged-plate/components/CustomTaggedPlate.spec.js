// Import the component being tested
import { mount, shallowMount, flushPromises } from '@vue/test-utils'
import CustomTaggedPlate from './CustomTaggedPlate.vue'
import { nextTick } from 'vue'

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
  exampleQcableData,
  exampleTag1GroupChromium,
} from '../testData/customTaggedPlateTestData.js'

describe('CustomTaggedPlate', () => {
  const mockLocation = {}
  const wrapperFactory = function () {
    return shallowMount(CustomTaggedPlate, {
      props: {
        sequencescapeApi: 'http://localhost:3000/api/v2',
        sequencescapeApiKey: 'development',
        purposeUuid: '',
        purposeName: 'Custom Tagged Plate',
        targetUrl: '',
        parentUuid: plateUuid,
        tagsPerWell: '1',
        locationObj: mockLocation,
      },
    })
  }

  describe('#computed:', () => {
    describe('isChildWellsValid:', () => {
      it('returns false if there are no childWells', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.isChildWellsValid).toEqual(false)
      })

      it('returns false if any wells with aliquots are invalid', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({
          parentPlate: exampleParentTag1Only,
          tag1Group: exampleTag1Group,
          walkingBy: 'manual by plate',
          direction: 'column',
          offsetTagsBy: 4,
        })

        expect(wrapper.vm.isChildWellsValid).toEqual(false)
      })

      it('returns true if all aliquots contain valid tag indexes', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({
          parentPlate: exampleParentTag1Only,
          tag1Group: exampleTag1Group,
          walkingBy: 'manual by plate',
          direction: 'column',
        })

        expect(wrapper.vm.isChildWellsValid).toEqual(true)
      })
    })

    describe('createButtonState:', () => {
      it('returns setup if tags are not valid', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({
          loading: true,
          parentPlate: exampleParentTag1Only,
          tag1Group: exampleTag1Group,
          walkingBy: 'manual by plate',
          direction: 'column',
          offsetTagsBy: 4,
        })

        expect(wrapper.vm.createButtonState).toEqual('setup')
      })

      it('returns pending if tags are valid and creation not started', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({
          loading: false,
          parentPlate: exampleParentTag1Only,
          tag1Group: exampleTag1Group,
          walkingBy: 'manual by plate',
          direction: 'column',
        })

        expect(wrapper.vm.createButtonState).toEqual('pending')
      })

      it('returns busy if tags are valid and creation in progress', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({
          loading: true,
          parentPlate: exampleParentTag1Only,
          tag1Group: exampleTag1Group,
          walkingBy: 'manual by plate',
          direction: 'column',
          creationRequestInProgress: true,
        })

        expect(wrapper.vm.createButtonState).toEqual('busy')
      })

      it('returns success if creation was successful', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({
          loading: false,
          parentPlate: exampleParentTag1Only,
          tag1Group: exampleTag1Group,
          walkingBy: 'manual by plate',
          direction: 'column',
          creationRequestInProgress: false,
          creationRequestSuccessful: true,
        })

        expect(wrapper.vm.createButtonState).toEqual('success')
      })

      it('returns failure if creation was unsuccessful', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({
          loading: false,
          parentPlate: exampleParentTag1Only,
          tag1Group: exampleTag1Group,
          walkingBy: 'manual by plate',
          direction: 'column',
          creationRequestInProgress: false,
          creationRequestSuccessful: false,
        })

        expect(wrapper.vm.createButtonState).toEqual('failure')
      })
    })

    describe('numberOfRows:', () => {
      it('returns null rows by default', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.numberOfRows).toEqual(null)
      })

      it('returns number of rows on parent plate', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({ parentPlate: exampleParent })

        expect(wrapper.vm.numberOfRows).toEqual(8)
      })
    })

    describe('numberOfColumns:', () => {
      it('returns null columns by default', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.numberOfColumns).toEqual(null)
      })

      it('returns number of columns on parent plate', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({ parentPlate: exampleParent })

        expect(wrapper.vm.numberOfColumns).toEqual(12)
      })
    })

    describe('tagsPerWellAsNumber:', () => {
      it('returns a numeric version of the prop tags per well', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setProps({ tagsPerWell: '4' })

        expect(wrapper.vm.tagsPerWellAsNumber).toEqual(4)
      })
    })

    describe('parentWells:', () => {
      it('returns empty object by default', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.parentWells).toEqual({})
      })

      it('returns wells from parent with pool indexes using requests as source', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({
          parentPlate: exampleParent,
        })

        expect(Object.keys(wrapper.vm.parentWells).length).toBe(4)
        expect(wrapper.vm.parentWells.A1.pool_index).toBe(1)
        expect(wrapper.vm.parentWells.A2.pool_index).toBe(1)
        expect(wrapper.vm.parentWells.A3.pool_index).toBe(1)
        expect(wrapper.vm.parentWells.A4.pool_index).toBe(1)
        expect(wrapper.vm.parentWells.A1.colour_index).toBe(1)
        expect(wrapper.vm.parentWells.A2.colour_index).toBe(1)
        expect(wrapper.vm.parentWells.A3.colour_index).toBe(1)
        expect(wrapper.vm.parentWells.A4.colour_index).toBe(1)
      })

      it('returns wells from parent with pool indexes using aliquot requests', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({
          parentPlate: exampleParentWithoutWellRequestsAsResource,
        })

        expect(Object.keys(wrapper.vm.parentWells).length).toBe(4)
        expect(wrapper.vm.parentWells.A1.pool_index).toBe(1)
        expect(wrapper.vm.parentWells.A2.pool_index).toBe(1)
        expect(wrapper.vm.parentWells.A3.pool_index).toBe(1)
        expect(wrapper.vm.parentWells.A4.pool_index).toBe(1)
        expect(wrapper.vm.parentWells.A1.colour_index).toBe(1)
        expect(wrapper.vm.parentWells.A2.colour_index).toBe(1)
        expect(wrapper.vm.parentWells.A3.colour_index).toBe(1)
        expect(wrapper.vm.parentWells.A4.colour_index).toBe(1)
      })

      it('returns wells from parent with pool indexes where multiple submissions set', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({
          parentPlate: exampleParentWithPools,
        })

        expect(Object.keys(wrapper.vm.parentWells).length).toBe(4)
        expect(wrapper.vm.parentWells.A1.pool_index).toBe(1)
        expect(wrapper.vm.parentWells.A2.pool_index).toBe(1)
        expect(wrapper.vm.parentWells.A3.pool_index).toBe(2)
        expect(wrapper.vm.parentWells.A4.pool_index).toBe(2)
        expect(wrapper.vm.parentWells.A1.colour_index).toBe(1)
        expect(wrapper.vm.parentWells.A2.colour_index).toBe(1)
        expect(wrapper.vm.parentWells.A3.colour_index).toBe(2)
        expect(wrapper.vm.parentWells.A4.colour_index).toBe(2)
      })
    })

    describe('childWells:', () => {
      it('returns empty object if parent wells does not exist', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.childWells).toEqual({})
      })

      it('returns parent wells if no tag layout', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({ parentPlate: exampleParent })

        expect(wrapper.vm.childWells).toEqual(wrapper.vm.parentWells)
      })

      it('returns valid wells object if all properties valid', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({
          parentPlate: exampleParentTag1Only,
          tag1Group: exampleTag1Group,
          walkingBy: 'manual by plate',
          direction: 'column',
        })

        const expectedChildWells = {
          A1: {
            position: 'A1',
            aliquotCount: 1,
            tagMapIds: [11],
            submId: '1',
            pool_index: 1,
            colour_index: 1,
            validity: { valid: true, message: '' },
          },
          A2: {
            position: 'A2',
            aliquotCount: 1,
            tagMapIds: [12],
            submId: '1',
            pool_index: 1,
            colour_index: 1,
            validity: { valid: true, message: '' },
          },
          A3: {
            position: 'A3',
            aliquotCount: 1,
            tagMapIds: [13],
            submId: '1',
            pool_index: 1,
            colour_index: 1,
            validity: { valid: true, message: '' },
          },
          A4: {
            position: 'A4',
            aliquotCount: 1,
            tagMapIds: [14],
            submId: '1',
            pool_index: 1,
            colour_index: 1,
            validity: { valid: true, message: '' },
          },
        }

        expect(wrapper.vm.childWells).toEqual(expectedChildWells)
      })

      it('returns invalid wells if not enough tags', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({
          parentPlate: exampleParentTag1Only,
          tag1Group: exampleTag1Group,
          walkingBy: 'manual by plate',
          direction: 'column',
          offsetTagsBy: 6,
        })

        const expectedChildWells = {
          A1: {
            position: 'A1',
            aliquotCount: 1,
            tagMapIds: [17],
            submId: '1',
            pool_index: 1,
            colour_index: 1,
            validity: { valid: true, message: '' },
          },
          A2: {
            position: 'A2',
            aliquotCount: 1,
            tagMapIds: [-1],
            submId: '1',
            pool_index: 1,
            colour_index: 1,
            validity: {
              valid: false,
              message: 'Missing tag ids for this well',
            },
          },
          A3: {
            position: 'A3',
            aliquotCount: 1,
            tagMapIds: [-1],
            submId: '1',
            pool_index: 1,
            colour_index: 1,
            validity: {
              valid: false,
              message: 'Missing tag ids for this well',
            },
          },
          A4: {
            position: 'A4',
            aliquotCount: 1,
            tagMapIds: [-1],
            submId: '1',
            pool_index: 1,
            colour_index: 1,
            validity: {
              valid: false,
              message: 'Missing tag ids for this well',
            },
          },
        }

        expect(wrapper.vm.childWells).toEqual(expectedChildWells)
      })

      it('returns valid wells object for a chromium plate', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setProps({
          tagsPerWell: '4',
        })

        wrapper.setData({
          parentPlate: exampleParent,
          tag1Group: exampleTag1GroupChromium,
          walkingBy: 'manual by plate',
          direction: 'column',
        })

        const expectedChildWells = {
          A1: {
            position: 'A1',
            aliquotCount: 1,
            tagMapIds: [1, 2, 3, 4],
            submId: '1',
            pool_index: 1,
            colour_index: 1,
            validity: { valid: true, message: '' },
          },
          A2: {
            position: 'A2',
            aliquotCount: 1,
            tagMapIds: [5, 6, 7, 8],
            submId: '1',
            pool_index: 1,
            colour_index: 1,
            validity: { valid: true, message: '' },
          },
          A3: {
            position: 'A3',
            aliquotCount: 1,
            tagMapIds: [9, 10, 11, 12],
            submId: '1',
            pool_index: 1,
            colour_index: 1,
            validity: { valid: true, message: '' },
          },
          A4: {
            position: 'A4',
            aliquotCount: 1,
            tagMapIds: [13, 14, 15, 16],
            submId: '1',
            pool_index: 1,
            colour_index: 1,
            validity: { valid: true, message: '' },
          },
        }

        expect(wrapper.vm.childWells).toEqual(expectedChildWells)
      })

      it('returns invalid wells where multiple tags and not enough tags', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setProps({
          tagsPerWell: '4',
        })

        wrapper.setData({
          parentPlate: exampleParentTag1Only,
          tag1Group: exampleTag1Group,
          walkingBy: 'manual by plate',
          direction: 'column',
          offsetTagsBy: 1,
        })

        const expectedChildWells = {
          A1: {
            position: 'A1',
            aliquotCount: 1,
            tagMapIds: [15, 16, 17, -1],
            submId: '1',
            pool_index: 1,
            colour_index: 1,
            validity: {
              valid: false,
              message: 'Missing tag ids for this well',
            },
          },
          A2: {
            position: 'A2',
            aliquotCount: 1,
            tagMapIds: [-1, -1, -1, -1],
            submId: '1',
            pool_index: 1,
            colour_index: 1,
            validity: {
              valid: false,
              message: 'Missing tag ids for this well',
            },
          },
          A3: {
            position: 'A3',
            aliquotCount: 1,
            tagMapIds: [-1, -1, -1, -1],
            submId: '1',
            pool_index: 1,
            colour_index: 1,
            validity: {
              valid: false,
              message: 'Missing tag ids for this well',
            },
          },
          A4: {
            position: 'A4',
            aliquotCount: 1,
            tagMapIds: [-1, -1, -1, -1],
            submId: '1',
            pool_index: 1,
            colour_index: 1,
            validity: {
              valid: false,
              message: 'Missing tag ids for this well',
            },
          },
        }

        expect(wrapper.vm.childWells).toEqual(expectedChildWells)
      })
    })

    describe('button text, style and disabled:', () => {
      it('returns the correct text depending on state', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({
          parentPlate: exampleParentTag1Only,
          tag1Group: exampleTag1Group,
          walkingBy: 'manual by plate',
          direction: 'column',
        })

        expect(wrapper.vm.createButtonState).toEqual('pending')
        expect(wrapper.vm.createButtonText).toEqual('Create new Custom Tagged plate')

        expect(wrapper.vm.createButtonStyle).toEqual('primary')
        expect(wrapper.vm.createButtonDisabled).toBe(false)
      })
    })

    describe('numberOfTags:', () => {
      it('returns zero if no tag group has been selected', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.numberOfTags).toBe(0)
      })

      it('returns the correct number if a tag 1 group has been selected', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({
          tag1Group: exampleTag1Group,
        })

        expect(wrapper.vm.numberOfTags).toBe(7)
      })

      it('returns the correct number if only tag 2 group has been selected', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({
          tag2Group: exampleTag2Group,
        })

        expect(wrapper.vm.numberOfTags).toBe(6)
      })

      it('returns the correct number if tag 1 group has more tags than tag 2 group', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({
          tag1Group: exampleTag1Group,
          tag2Group: exampleTag2Group,
        })

        expect(wrapper.vm.numberOfTags).toBe(6)
      })
    })

    describe('useableTagMapIds:', () => {
      it('returns an empty array if no tag groups have been selected', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.useableTagMapIds).toEqual([])
      })

      it('returns an array of the tag 1 group map ids if only tag 1 group is selected', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({
          tag1Group: exampleTag1Group,
        })

        expect(wrapper.vm.useableTagMapIds).toEqual([11, 12, 13, 14, 15, 16, 17])
      })

      it('returns an array of the tag 2 group map ids if only tag 2 group is selected', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({
          tag2Group: exampleTag2Group,
        })

        expect(wrapper.vm.useableTagMapIds).toEqual([21, 22, 23, 24, 25, 26])
      })

      it('returns a shortened array of the tag 1 group map ids if both groups are selected and tag group 2 is smaller', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({
          tag1Group: exampleTag1Group,
          tag2Group: exampleTag2Group,
        })

        expect(wrapper.vm.useableTagMapIds).toEqual([11, 12, 13, 14, 15, 16])
      })

      it('returns a full array of the tag 1 group map ids if both groups are selected and tag group 2 is longer', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({
          tag1Group: exampleTag1Group,
          tag2Group: exampleTag2GroupLonger,
        })

        expect(wrapper.vm.useableTagMapIds).toEqual([11, 12, 13, 14, 15, 16, 17])
      })
    })

    describe('numberOfTargetWells:', () => {
      it('returns zero if no parent plate exists', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({ walkingBy: 'manual by plate' })

        expect(wrapper.vm.numberOfTargetWells).toBe(0)
      })

      it('returns zero if no walking by is set', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({ parentPlate: exampleParent })

        expect(wrapper.vm.numberOfTargetWells).toBe(0)
      })

      it('returns correct value for a fixed plate', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({
          parentPlate: exampleParent,
          walkingBy: 'wells of plate',
        })

        expect(wrapper.vm.numberOfTargetWells).toBe(4)
      })

      it('returns correct value for a plate by sequence', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({
          parentPlate: exampleParentSequential,
          walkingBy: 'manual by plate',
        })

        expect(wrapper.vm.numberOfTargetWells).toBe(3)
      })

      it('returns correct value for a plate with pools', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({
          parentPlate: exampleParentWithPools,
          walkingBy: 'manual by pool',
        })

        expect(wrapper.vm.numberOfTargetWells).toBe(2)
      })
    })
  })

  describe('#rendering tests:', () => {
    it('renders child components for single tag per well', async () => {
      const wrapper = mount(CustomTaggedPlate, {
        props: {
          sequencescapeApi: 'http://localhost:3000/api/v2',
          sequencescapeApiKey: 'development',
          purposeUuid: '',
          purposeName: 'Custom Tagged Plate',
          targetUrl: '',
          parentUuid: plateUuid,
          tagsPerWell: '1',
          locationObj: mockLocation,
        },
        global: {
          stubs: {
            'lb-parent-plate-lookup': true,
            'lb-parent-plate-view': true,
            'lb-tag-substitution-details': true,
            'lb-tag-layout-manipulations': true,
            'lb-well-modal': true,
          },
        },
      })

      wrapper.setData({
        parentPlate: exampleParent,
      })

      await nextTick()

      expect(wrapper.find('lb-parent-plate-view-stub').exists()).toBe(true)
      expect(wrapper.find('lb-tag-substitution-details-stub').exists()).toBe(true)

      expect(wrapper.find('lb-tag-layout-manipulations-stub').exists()).toBe(true)

      expect(wrapper.find('lb-well-modal-stub').exists()).toBe(true)
    })

    it('renders child components for multiple tags per well', async () => {
      const wrapper = mount(CustomTaggedPlate, {
        props: {
          sequencescapeApi: 'http://localhost:3000/api/v2',
          sequencescapeApiKey: 'development',
          purposeUuid: '',
          purposeName: 'Custom Tagged Plate',
          targetUrl: '',
          parentUuid: plateUuid,
          tagsPerWell: '4',
          locationObj: mockLocation,
        },
        global: {
          stubs: {
            'lb-parent-plate-lookup': true,
            'lb-parent-plate-view': true,
            'lb-tag-substitution-details': true,
            'lb-tag-layout-manipulations-multiple': true,
            'lb-well-modal': true,
          },
        },
      })

      wrapper.setData({
        parentPlate: exampleParent,
      })

      await nextTick()

      expect(wrapper.find('lb-parent-plate-view-stub').exists()).toBe(true)
      expect(wrapper.find('lb-tag-substitution-details-stub').exists()).toBe(true)

      expect(wrapper.find('lb-tag-layout-manipulations-multiple-stub').exists()).toBe(true)

      expect(wrapper.find('lb-well-modal-stub').exists()).toBe(true)
    })

    it('renders a submit button', async () => {
      const wrapper = mount(CustomTaggedPlate, {
        props: {
          sequencescapeApi: 'http://localhost:3000/api/v2',
          sequencescapeApiKey: 'development',
          purposeUuid: '',
          purposeName: 'Custom Tagged Plate',
          targetUrl: '',
          parentUuid: plateUuid,
          tagsPerWell: '4',
          locationObj: mockLocation,
        },
        global: {
          stubs: {
            'lb-parent-plate-lookup': true,
            'lb-parent-plate-view': true,
            'lb-tag-substitution-details': true,
            'lb-tag-layout-manipulations-multiple': true,
            'lb-well-modal': true,
          },
        },
      })

      await flushPromises()

      expect(wrapper.find('#custom_tagged_plate_submit_button').exists()).toBe(true)
    })
  })

  describe('#integration tests:', () => {
    it('disallows tag substitutions for chromium plates', async () => {
      const wrapper = wrapperFactory()

      await wrapper.setProps({
        tagsPerWell: '4',
      })

      wrapper.setData({
        parentPlate: exampleParent,
        tag1Group: exampleTag1Group,
        tag2Group: exampleTag2Group,
        direction: 'row',
        walkingBy: 'wells of plate',
      })

      expect(wrapper.vm.isMultipleTaggedPlate).toBe(true)
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
        tagSubstitutions: { 14: 15 },
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
        tagSubstitutions: { 13: 11 },
      })

      expect(wrapper.vm.childWells['A1'].validity.valid).toBe(false)
      expect(wrapper.vm.childWells['A1'].validity.message).toBe('Tag clash with the following: A3')

      expect(wrapper.vm.childWells['A3'].validity.valid).toBe(false)
      expect(wrapper.vm.childWells['A3'].validity.message).toBe('Tag clash with the following: A1')
    })

    it('sends a post request when the create plate button is clicked', async () => {
      const wrapper = wrapperFactory()

      await wrapper.setProps({
        purposeUuid: 'purpose-uuid',
        targetUrl: 'example/example',
        parentUuid: 'parent-plate-uuid',
        tagsPerWell: '1',
      })

      await wrapper.setData({
        tagPlate: exampleQcableData.plate,
        tag1Group: exampleTag1Group,
        tag2Group: exampleTag2Group,
        direction: 'column',
        walkingBy: 'manual by plate',
        offsetTagsBy: 1,
        tagSubstitutions: {},
      })

      const expectedPayload = {
        plate: {
          filters: {},
          purpose_uuid: 'purpose-uuid',
          parent_uuid: 'parent-plate-uuid',
          tag_layout: {
            tag_group_uuid: 'tag-1-group-uuid',
            tag2_group_uuid: 'tag-2-group-uuid',
            direction: 'column',
            walking_by: 'manual by plate',
            initial_tag: 1,
            substitutions: {},
            tags_per_well: 1,
          },
          tag_plate: {
            asset_uuid: 'asset-uuid',
            template_uuid: 'tag-template-uuid',
            state: 'available',
          },
        },
      }

      mockLocation.href = null
      wrapper.vm.$axios = vi
        .fn()
        .mockResolvedValue({ data: { redirect: 'http://wwww.example.com', message: 'Creating...' } })

      // to click the button we would need to mount rather than shallowMount, but then we run into issues with mocking other database calls
      wrapper.vm.createPlate()

      await flushPromises()

      expect(wrapper.vm.$axios).toHaveBeenCalledTimes(1)
      expect(wrapper.vm.$axios).toHaveBeenCalledWith({
        url: 'example/example',
        method: 'post',
        headers: { 'X-Requested-With': 'XMLHttpRequest' },
        data: expectedPayload,
      })
      expect(wrapper.vm.progressMessage).toEqual('Creating...')
      expect(mockLocation.href).toEqual('http://wwww.example.com')
    })
  })
})
