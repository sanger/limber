import Vue from 'vue'
import TagLayout from 'custom-tagged-plate/components/mixins/tagLayout'
import {
  nullTagGroup,
  exampleTagGroupsList
} from 'custom-tagged-plate/testData/customTaggedPlateTestData.js'

describe('TagLayout mixin', () => {
  let cmp, tagLayout, data

  beforeEach(() => {
    data = { api: {}, numberOfTags: 10, numberOfTargetWells: 10, tagsPerWell: 1 }
    cmp = Vue.extend({ mixins: [TagLayout] })
    tagLayout = new cmp({
      propsData: data,
      stubs: {
        'lb-tag-groups-lookup': true,
        'lb-tag-offset': true
      }
    })
  })

  describe('checking props:', () => {
    it('has an api', () => {
      expect(tagLayout.api).toEqual(data.api)
    })

    it('has a number of tags', () => {
      expect(tagLayout.numberOfTags).toEqual(data.numberOfTags)
    })

    it('has a number of target wells', () => {
      expect(tagLayout.numberOfTargetWells).toEqual(data.numberOfTargetWells)
    })

    it('has a tagsPerWell', () => {
      expect(tagLayout.tagsPerWell).toEqual(data.tagsPerWell)
    })
  })

  describe('checking default data values', () => {
    it('has a directions array with the correct number of options', () => {
      expect(tagLayout.directionOptions.length).toBe(5)
    })
  })

  describe('checking computed values: ', () => {
    describe('tag1Group:', () => {
      it('returns a null tag group by default', () => {
        expect(tagLayout.tag1Group).toEqual(nullTagGroup)
      })

      it('returns a valid tag 1 group if the id matches a group in the list', () => {
        tagLayout.tagGroupsList = exampleTagGroupsList
        tagLayout.tag1GroupId = 1

        const expectedTagGroup = {
          id: '1',
          uuid: 'tag-1-group-uuid',
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
        }

        expect(tagLayout.tag1Group).toEqual(expectedTagGroup)
      })
    })

    describe('tag2Group:', () => {
      it('returns a null tag 2 group by default', () => {
        expect(tagLayout.tag2Group).toEqual(nullTagGroup)
      })

      it('returns a valid tag 2 group if the id matches a group in the list', () => {
        tagLayout.tagGroupsList = exampleTagGroupsList
        tagLayout.tag2GroupId = 1

        const expectedTagGroup = {
          id: '1',
          uuid: 'tag-1-group-uuid',
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
        }

        expect(tagLayout.tag2Group).toEqual(expectedTagGroup)
      })
    })

    describe('coreTagGroupOptions', () => {
      it('returns empty array if tag groups list empty', () => {
        expect(tagLayout.coreTagGroupOptions).toEqual([])
      })

      it('returns valid array if tag groups list set', () => {
        tagLayout.tagGroupsList = exampleTagGroupsList

        const expectedCoreTagGroupOptions = [
          { value: '1', text: 'Tag Group 1' },
          { value: '2', text: 'Tag Group 2' }
        ]

        expect(tagLayout.coreTagGroupOptions).toEqual(expectedCoreTagGroupOptions)
      })
    })

    describe('tag1GroupOptions:', () => {
      it('returns empty array for tag 1 groups if tag groups list empty', () => {
        expect(tagLayout.tag1GroupOptions).toEqual([{ value: null, text: 'Please select an i7 Tag 1 group...' }])
      })

      it('returns valid array of tag 1 groups if tag groups list set', () => {
        tagLayout.tagGroupsList = exampleTagGroupsList

        const expectedTag1GroupOptions = [
          { value: null, text: 'Please select an i7 Tag 1 group...' },
          { value: '1', text: 'Tag Group 1' },
          { value: '2', text: 'Tag Group 2' }
        ]

        expect(tagLayout.tag1GroupOptions).toEqual(expectedTag1GroupOptions)
      })
    })

    describe('tag2GroupOptions:', () => {
      it('returns empty array for tag 2 groups if tag groups list empty', () => {
        expect(tagLayout.tag2GroupOptions).toEqual([{ value: null, text: 'Please select an i5 Tag 2 group...' }])
      })

      it('returns valid array of tag 2 groups if tag groups list set', () => {
        tagLayout.tagGroupsList = exampleTagGroupsList

        const expectedTag2GroupOptions = [
          { value: null, text: 'Please select an i5 Tag 2 group...' },
          { value: '1', text: 'Tag Group 1' },
          { value: '2', text: 'Tag Group 2' }
        ]

        expect(tagLayout.tag2GroupOptions).toEqual(expectedTag2GroupOptions)
      })
    })
  })
})
