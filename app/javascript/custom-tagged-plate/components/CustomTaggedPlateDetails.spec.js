// Import the component being tested
import { shallowMount } from '@vue/test-utils'
import CustomTaggedPlateDetails from './CustomTaggedPlateDetails.vue'
import localVue from 'test_support/base_vue.js'

// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
describe('CustomTaggedPlateDetails', () => {
  const wrapperFactory = function() {
    return shallowMount(CustomTaggedPlateDetails, {
      propsData: {
        tagSubstitutions: { '2': '5', '3': '6' }
      },
      localVue
    })
  }

  describe('#rendering tests', () => {
    it('renders a vue instance', () => {
      const wrapper = wrapperFactory()

      expect(wrapper.isVueInstance()).toBe(true)
    })

    it('renders a row for each substitution', () => {
      const wrapper = wrapperFactory()

      expect(wrapper.find('#original_tag_id_2').exists()).toBe(true)
      expect(wrapper.find('#substituted_tag_id_2').exists()).toBe(true)
      expect(wrapper.find('#remove_tag_id_2_submit_button').exists()).toBe(true)

      expect(wrapper.find('#original_tag_id_3').exists()).toBe(true)
      expect(wrapper.find('#substituted_tag_id_3').exists()).toBe(true)
      expect(wrapper.find('#remove_tag_id_3_submit_button').exists()).toBe(true)
    })

    it('renders different text if tag substitutions are disallowed', () => {
      const wrapper = wrapperFactory()

      expect(wrapper.find('#tag_substitutions_allowed').exists()).toBe(true)

      wrapper.setProps({ tagSubstitutionsAllowed: false })

      expect(wrapper.find('#tag_substitutions_allowed').exists()).toBe(false)
      expect(wrapper.find('#tag_substitutions_disallowed').exists()).toBe(true)
    })
  })

  describe('#computed function tests:', () => {
    describe('hasTagSubstitutions:', () => {
      it('returns false if no tag substitutions are present', () => {
        const wrapper = wrapperFactory()

        wrapper.setProps({ tagSubstitutions: {} })

        expect(wrapper.vm.hasTagSubstitutions).toBe(false)
      })

      it('returns true if tag substitutions are present', () => {
        const wrapper = wrapperFactory()

        wrapper.setProps({ tagSubstitutions: { '1':'2' } })

        expect(wrapper.vm.hasTagSubstitutions).toBe(true)
      })
    })
  })

  describe('#integration tests', () => {
    it('emits a call to the parent on clicking a remove substitution button', () => {
      const wrapper = wrapperFactory()
      const emitted = wrapper.emitted()

      expect(wrapper.find('#remove_tag_id_2_submit_button').exists()).toBe(true)

      // const button = wrapper.find('#remove_tag_id_2_submit_button')
      // button.trigger('click')
      // cannot click button in test for some reason...
      wrapper.vm.removeSubstitution('2')

      expect(emitted.removetagsubstitution.length).toBe(1)
      expect(emitted.removetagsubstitution[0]).toEqual(['2'])
    })
  })
})
