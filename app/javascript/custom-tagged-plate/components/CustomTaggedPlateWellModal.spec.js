// Import the component being tested
import { shallowMount } from '@vue/test-utils'
import CustomTaggedPlateWellModal from './CustomTaggedPlateWellModal.vue'
import localVue from 'test_support/base_vue.js'

// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
describe('CustomTaggedPlateWellModal', () => {
  const wrapperFactory = function() {
    return shallowMount(CustomTaggedPlateWellModal, {
      propsData: {
        wellModalDetails: {
          position: 'A1',
          originalTag: 1,
          tagMapIds: [1,2,3],
          validity: { valid: true, message: '' },
          existingSubstituteTagId: '2'
        },
        isWellModalVisible: true
      },
      localVue
    })
  }

  const invalidEntryWellModalDetails = {
    position: 'A1',
    originalTag: 1,
    tagMapIds: [1,2,3],
    validity: { valid: true, message: '' },
    existingSubstituteTagId: null
  }

  const tagClashWellModalDetails = {
    position: 'A1',
    originalTag: 1,
    tagMapIds: [1,2,3],
    validity: { valid: false, message: 'Tag clash with Submission' },
    existingSubstituteTagId: null
  }

  describe('#rendering tests', () => {
    it('renders a vue instance', () => {
      const wrapper = wrapperFactory()

      expect(wrapper.isVueInstance()).toBe(true)
    })

    it('renders appropriate fields', () => {
      const wrapper = wrapperFactory()

      expect(wrapper.find('#original_tag_number_input').exists()).toBe(true)
      expect(wrapper.find('#substitute_tag_number_input').exists()).toBe(true)
      expect(wrapper.find('#well_error_message').exists()).toBe(false)
    })

    it('renders an invalid message if one is provided', () => {
      const wrapper = wrapperFactory()

      wrapper.setProps({ wellModalDetails: tagClashWellModalDetails })

      expect(wrapper.find('#well_error_message').exists()).toBe(true)
      expect(wrapper.find('#well_error_message').text()).toEqual('Tag clash with Submission')
    })

    it('does not render originalTag if one is not provided', () => {
      const wrapper = wrapperFactory()

      wrapper.setProps({
        wellModalDetails: {
          position: 'A1',
          originalTag: null,
          tagMapIds: [1,2,3],
          validity: { valid: false, message: 'No tag in this well' },
          existingSubstituteTagId: ''
        }
      })

      expect(wrapper.find('#original_tag_number_input').exists()).toBe(false)
    })

    it('does not render substituteTagId if no tagMapIds are provided', () => {
      const wrapper = wrapperFactory()

      wrapper.setProps({
        wellModalDetails: {
          position: 'A1',
          originalTag: 1,
          tagMapIds: [],
          validity: { valid: false, message: 'No tag in this well' },
          existingSubstituteTagId: ''
        }
      })

      expect(wrapper.find('#substitute_tag_number_input').exists()).toBe(false)
    })
  })

  describe('#computed function tests:', () => {
    describe('wellModalTitle:', () => {
      it('returns the correct title', () => {
        const wrapper = wrapperFactory()

        expect(wrapper.vm.wellModalTitle).toEqual('Well: A1')
      })
    })

    describe('state:', () => {
      it('returns the correct state for a invalid substitution', () => {
        const wrapper = wrapperFactory()

        wrapper.setProps({ wellModalDetails: invalidEntryWellModalDetails })
        wrapper.setData({ substituteTagId: '5' })

        expect(wrapper.vm.state).toBe(false)
      })

      it('returns the correct state for a valid substitution', () => {
        const wrapper = wrapperFactory()

        wrapper.setData({ substituteTagId: '3' })

        expect(wrapper.vm.state).toBe(true)
      })
    })
  })

  describe('#integration tests', () => {
    it('emits a call to the parent on clicking Ok button with valid substitution', () => {
      const wrapper = wrapperFactory()
      const emitted = wrapper.emitted()

      wrapper.setData({ substituteTagId: '3' })

      // cannot click ok button in modal from here, plus cannot handle evt.preventDefault
      wrapper.vm.handleWellModalOk()

      expect(emitted.wellmodalsubtituteselected.length).toBe(1)
      expect(emitted.wellmodalsubtituteselected[0]).toEqual([3])
    })
  })
})
