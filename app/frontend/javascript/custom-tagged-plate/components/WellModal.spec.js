// Import the component being tested
import { mount } from '@vue/test-utils'
import WellModal from './WellModal.vue'
import { nextTick } from 'vue'

describe('WellModal', () => {
  const wrapperFactory = function () {
    return mount(WellModal, {
      props: {
        wellModalDetails: {
          position: 'A1',
          originalTag: 1,
          tagMapIds: [1, 2, 3],
          validity: { valid: true, message: '' },
          existingSubstituteTagId: '2',
        },
        isWellModalVisible: true,
      },
      global: {
        stubs: {
          teleport: true,
        },
      },
    })
  }

  describe('#computed function tests:', () => {
    describe('wellModalTitle:', () => {
      it('returns the correct title', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.wellModalTitle).toEqual('Well: A1 - Tag Substitution')
      })
    })

    describe('wellModalState:', () => {
      it('returns null if there are no tagMapIds', async () => {
        const wrapper = wrapperFactory()

        const emptyWellModalDetails = {
          position: 'A1',
          originalTag: 1,
          tagMapIds: [],
          validity: { valid: true, message: '' },
          existingSubstituteTagId: null,
        }

        wrapper.setProps({ wellModalDetails: emptyWellModalDetails })
        wrapper.setData({ substituteTagId: '5' })

        await wrapper.vm.$nextTick()

        expect(wrapper.vm.wellModalState).toBe(null)
      })

      it('returns the correct state for a invalid substitution', () => {
        const wrapper = wrapperFactory()

        const invalidEntryWellModalDetails = {
          position: 'A1',
          originalTag: 1,
          tagMapIds: [1, 2, 3],
          validity: { valid: true, message: '' },
          existingSubstituteTagId: null,
        }

        wrapper.setProps({ wellModalDetails: invalidEntryWellModalDetails })
        wrapper.setData({ substituteTagId: '5' })

        expect(wrapper.vm.wellModalState).toBe(false)
      })

      it('returns the correct state for a valid substitution', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ substituteTagId: '3' })

        expect(wrapper.vm.wellModalState).toBe(true)
      })
    })

    describe('wellModalInvalidFeedback', () => {
      it('returns the correct text when the value is blank', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.wellModalInvalidFeedback).toEqual('')
      })

      it('returns the correct text when the value is a valid tag map id', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ substituteTagId: '3' })

        expect(wrapper.vm.wellModalInvalidFeedback).toEqual('')
      })

      it('returns the correct text when the value is an invalid tag map id', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ substituteTagId: '5' })

        expect(wrapper.vm.wellModalInvalidFeedback).toEqual('Number entered is not a valid tag map id')
      })
    })
  })

  describe('#rendering tests', () => {
    it('renders appropriate fields', () => {
      const wrapper = wrapperFactory()

      expect(wrapper.find('#original_tag_number_input').exists()).toBe(true)
      expect(wrapper.find('#substitute_tag_number_input').exists()).toBe(true)
      expect(wrapper.find('#well_error_message').exists()).toBe(false)
    })

    it('renders an invalid message if one is provided', async () => {
      const wrapper = wrapperFactory()

      const tagClashWellModalDetails = {
        position: 'A1',
        originalTag: 1,
        tagMapIds: [1, 2, 3],
        validity: { valid: false, message: 'Tag clash with Submission' },
        existingSubstituteTagId: null,
      }

      wrapper.setProps({ wellModalDetails: tagClashWellModalDetails })

      await nextTick()

      expect(wrapper.find('#well_error_message').exists()).toBe(true)
      expect(wrapper.find('#well_error_message').text()).toEqual('Tag clash with Submission')
    })

    it('does not render originalTag if one is not provided', async () => {
      const wrapper = wrapperFactory()

      wrapper.setProps({
        wellModalDetails: {
          position: 'A1',
          originalTag: null,
          tagMapIds: [1, 2, 3],
          validity: { valid: false, message: 'No tag in this well' },
          existingSubstituteTagId: '',
        },
      })

      await wrapper.vm.$nextTick()

      expect(wrapper.find('#original_tag_number_input').exists()).toBe(false)
    })

    it('does not render substituteTagId if no tagMapIds are provided', async () => {
      const wrapper = wrapperFactory()

      wrapper.setProps({
        wellModalDetails: {
          position: 'A1',
          originalTag: 1,
          tagMapIds: [],
          validity: { valid: false, message: 'No tag in this well' },
          existingSubstituteTagId: '',
        },
      })

      await wrapper.vm.$nextTick()

      expect(wrapper.find('#substitute_tag_number_input').exists()).toBe(false)
    })
  })

  describe('#integration tests', () => {
    it('emits a call to the parent on clicking Ok button with valid substitution', () => {
      const wrapper = wrapperFactory()

      wrapper.setData({ substituteTagId: '3' })

      // cannot click ok button in modal from here, plus cannot handle evt.preventDefault
      wrapper.vm.handleWellModalOk()

      const emitted = wrapper.emitted()
      expect(emitted.wellmodalsubtituteselected.length).toBe(1)
      expect(emitted.wellmodalsubtituteselected[0]).toEqual([3])
    })
  })
})
