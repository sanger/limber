// Import the component being tested
import { mount } from '@vue/test-utils'
import TagOffset from './TagOffset.vue'

// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
describe('TagOffset', () => {
  const wrapperFactory = function () {
    return mount(TagOffset, {
      props: {
        numberOfTags: 5,
        numberOfTargetWells: 5,
        tagsPerWell: 1,
      },
    })
  }

  describe('#computed function tests:', () => {
    describe('offsetTagsByMax:', () => {
      it('returns expected value when no spare tags', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.offsetTagsByMax).toBe(0)
        expect(wrapper.vm.offsetTagsByPlaceholder).toBe('No spare tags...')
      })

      it('returns expected value if tags are in excess', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setProps({ numberOfTags: 10 })

        expect(wrapper.vm.offsetTagsByMax).toBe(5)
        expect(wrapper.vm.offsetTagsByPlaceholder).toBe('Enter offset number...')
      })

      it('returns a negative number when not enough tags', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setProps({ numberOfTargetWells: 10 })

        expect(wrapper.vm.offsetTagsByMax).toBe(-5)
        expect(wrapper.vm.offsetTagsByPlaceholder).toBe('Not enough tags...')
      })

      it('returns null if there are no tags', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setProps({ numberOfTags: 0 })

        expect(wrapper.vm.offsetTagsByMax).toEqual(null)
        expect(wrapper.vm.offsetTagsByPlaceholder).toBe('Select tags first...')
      })

      it('returns null if there are no target wells', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setProps({ numberOfTargetWells: 0 })

        expect(wrapper.vm.offsetTagsByMax).toEqual(null)
        expect(wrapper.vm.offsetTagsByPlaceholder).toBe('No target wells...')
      })

      it('returns expected value for multiple tagged plates when no tags spare', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setProps({
          numberOfTags: 48,
          numberOfTargetWells: 12,
          tagsPerWell: 4,
        })

        expect(wrapper.vm.offsetTagsByMax).toBe(0)
        expect(wrapper.vm.offsetTagsByPlaceholder).toBe('No spare tags...')
      })

      it('returns expected value for multiple tagged plates when tags in excess', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setProps({
          numberOfTags: 48,
          numberOfTargetWells: 8,
          tagsPerWell: 4,
        })

        expect(wrapper.vm.offsetTagsByMax).toBe(4)
        expect(wrapper.vm.offsetTagsByPlaceholder).toBe('Enter offset number...')
      })

      it('returns a negative value for multiple tagged plates when not enough tags', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setProps({
          numberOfTags: 48,
          numberOfTargetWells: 20,
          tagsPerWell: 4,
        })

        expect(wrapper.vm.offsetTagsByMax).toBe(-8)
        expect(wrapper.vm.offsetTagsByPlaceholder).toBe('Not enough tags...')
      })
    })

    describe('offsetTagsByState:', () => {
      it('returns null if the start at tag max is invalid', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setProps({ numberOfTags: 10, numberOfTargetWells: 20 })

        expect(wrapper.vm.offsetTagsByMax).toBe(-10)
        expect(wrapper.vm.offsetTagsByState).toEqual(null)
      })

      it('returns null if the offset has no value', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        await wrapper.setData({ offsetTagsBy: '' })

        expect(wrapper.vm.offsetTagsByState).toEqual(null)
      })

      it('returns null if the offset is zero', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        await wrapper.setData({ offsetTagsBy: '0' })

        expect(wrapper.vm.offsetTagsByState).toEqual(null)
      })

      it('returns true if the entered number is valid', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        await wrapper.setData({ offsetTagsBy: '5' })

        expect(wrapper.vm.offsetTagsByMax).toBe(9)
        expect(wrapper.vm.offsetTagsByState).toBe(true)
      })

      it('returns false if the entered number is too high', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        await wrapper.setData({ offsetTagsBy: '11' })

        expect(wrapper.vm.offsetTagsByMax).toBe(9)
        expect(wrapper.vm.offsetTagsByState).toBe(false)
      })
    })

    describe('offsetTagsByInvalidFeedback:', () => {
      it('returns empty string if the entered number is null', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setData({ offsetTagsBy: '0' })

        expect(wrapper.vm.offsetTagsByInvalidFeedback).toEqual('')
      })

      it('returns empty string if the max is not set', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setProps({ numberOfTags: 0, numberOfTargetWells: 0 })
        await wrapper.setData({ offsetTagsBy: '1' })

        expect(wrapper.vm.offsetTagsByMax).toEqual(null)
        expect(wrapper.vm.offsetTagsByInvalidFeedback).toEqual('')
      })

      it('returns empty string if the entered number is valid', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        await wrapper.setData({ offsetTagsBy: '5' })

        expect(wrapper.vm.offsetTagsByMax).toBe(9)
        expect(wrapper.vm.offsetTagsByInvalidFeedback).toEqual('')
      })

      it('returns correctly if the entered number is too high', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setProps({ numberOfTags: 19, numberOfTargetWells: 10 })
        await wrapper.setData({ offsetTagsBy: '11' })

        expect(wrapper.vm.offsetTagsByMax).toBe(9)
        expect(wrapper.vm.offsetTagsByInvalidFeedback).toEqual('Offset must be less than or equal to 9')
      })

      it('returns correctly if there are not enough tags to fill the plate', async () => {
        const wrapper = wrapperFactory()

        await wrapper.setProps({ numberOfTags: 10, numberOfTargetWells: 20 })
        await wrapper.setData({ offsetTagsBy: '0' })

        expect(wrapper.vm.offsetTagsByMax).toBe(-10)
        expect(wrapper.vm.offsetTagsByInvalidFeedback).toEqual('Not enough tags to fill wells with aliquots')
      })
    })
  })

  describe('#rendering tests:', () => {
    it('renders an offset tags by select number input', () => {
      const wrapper = wrapperFactory()

      expect(wrapper.find('#offset_tags_by_input').exists()).toBe(true)
    })
  })
})
