import localVue from 'test_support/base_vue'
import { mount } from '@vue/test-utils'
import AssetCustomMetadataAddForm from './AssetCustomMetadataAddForm.vue'

describe('AssetCustomMetadataAddForm', () => {
  let customMetadataFields = '{}'
  let assetId = '123'
  let customMetadata = {}
  let customMetadatumCollectionsId

  const wrapperFactory = function () {
    const parent = {
      data() {
        return {
          addCustomMetadata() {},
          refreshCustomMetadata() {},
          customMetadata: customMetadata,
          customMetadatumCollectionsId: customMetadatumCollectionsId,
        }
      },
    }

    return mount(AssetCustomMetadataAddForm, {
      localVue,
      parentComponent: parent,
      propsData: { customMetadataFields: customMetadataFields, assetId: assetId },
    })
  }

  describe('#form', () => {
    describe('when customMetadataFields is empty', () => {
      it('does not render the form or the button', () => {
        customMetadataFields = '{}'
        let wrapper = wrapperFactory([])

        expect(wrapper.find('#custom-metadata-input-form').exists()).toBe(false)
        expect(wrapper.find('#asset_custom_metadata_submit_button').exists()).toBe(false)
      })
    })

    describe('when customMetadataFields is not empty', () => {
      it('renders a form, with the correct inputs, and the create button', () => {
        customMetadataFields =
          '{"RT LunaScript Super Mix":{"key":"rt_lunascript_super_mix"},"RT NFW":{"key":"rt_nfw"},"RT DFD Syringe Lot Number":{"key":"rt_dfd_syringe_lot_number"}}'
        let wrapper = wrapperFactory([])

        expect(wrapper.find('#custom-metadata-input-form').exists()).toBe(true)
        expect(wrapper.find('#rt_lunascript_super_mix').exists()).toBe(true)
        expect(wrapper.find('#rt_dfd_syringe_lot_number').exists()).toBe(true)

        expect(wrapper.find('#asset_custom_metadata_submit_button').exists()).toBe(true)
        expect(wrapper.find('#asset_custom_metadata_submit_button').text()).toEqual(
          'Add Custom Metadata to Sequencescape'
        )
      })
    })
  })

  describe('props', () => {
    it('can be passed', () => {
      let wrapper = wrapperFactory([])
      expect(wrapper.vm.customMetadataFields).toEqual(customMetadataFields)
      expect(wrapper.vm.assetId).toEqual(assetId)
    })
  })

  describe('#data', () => {
    it('is initialised', () => {
      customMetadataFields = '{"RT LunaScript Super Mix":{"key":"rt_lunascript_super_mix"}}'
      let wrapper = wrapperFactory([])

      expect(wrapper.vm.state).toBe('pending')
      expect(wrapper.vm.form).toStrictEqual({ rt_lunascript_super_mix: '' })
      let expectedNormalisedFields = { 'RT LunaScript Super Mix': { key: 'rt_lunascript_super_mix' } }
      expect(wrapper.vm.normalizedFields).toEqual(expectedNormalisedFields)
    })
  })

  describe('#computed', () => {
    it('customMetadataFieldsExist', () => {
      customMetadataFields =
        '{"RT LunaScript Super Mix":{"key":"rt_lunascript_super_mix"},"RT NFW":{"key":"rt_nfw"},"RT DFD Syringe Lot Number":{"key":"rt_dfd_syringe_lot_number"}}'
      let wrapper = wrapperFactory([])
      expect(wrapper.vm.customMetadataFieldsExist).toEqual(true)

      customMetadataFields = '{}'
      wrapper = wrapperFactory([])
      expect(wrapper.vm.customMetadataFieldsExist).toEqual(false)
    })
  })

  describe('#methods', () => {
    describe('#onUpdate', () => {
      it('sets state to pending if it isnt already', () => {
        customMetadataFields = '{}'
        let wrapper = wrapperFactory([])
        wrapper.vm.state = 'busy'
        wrapper.vm.onUpdate()
        expect(wrapper.vm.state).toEqual('pending')
      })
    })
    describe('#setupForm', () => {
      it('correctly sets the form to empty when no fields exist', () => {
        customMetadataFields = '{}'
        let wrapper = wrapperFactory([])
        expect(wrapper.vm.form).toStrictEqual({})
      })

      it('correctly sets the form when fields exist', () => {
        customMetadataFields =
          '{"RT LunaScript Super Mix":{"key":"rt_lunascript_super_mix"},"RT NFW":{"key":"rt_nfw"},"RT DFD Syringe Lot Number":{"key":"rt_dfd_syringe_lot_number"}}'
        let wrapper = wrapperFactory([])

        let expected = {
          rt_dfd_syringe_lot_number: '',
          rt_lunascript_super_mix: '',
          rt_nfw: '',
        }
        expect(wrapper.vm.form).toStrictEqual(expected)
      })
    })

    describe('#fetchCustomMetadata', () => {
      it('updates the form when response includes form fields', async () => {
        customMetadataFields = '{"RT LunaScript Super Mix":{"key":"rt_lunascript_super_mix"}}'
        let wrapper = wrapperFactory([])

        wrapper.vm.$parent.refreshCustomMetadata = jest.fn().mockResolvedValue(true)

        const customMetadataMock = jest.fn()
        customMetadataMock.mockReturnValue({ rt_lunascript_super_mix: 'UPDATED' })
        wrapper.vm.$parent.customMetadata = customMetadataMock()

        await wrapper.vm.fetchCustomMetadata()

        expect(wrapper.vm.$parent.refreshCustomMetadata).toHaveBeenCalled()
        expect(wrapper.vm.form).toEqual({
          rt_lunascript_super_mix: 'UPDATED',
        })
      })

      it('updates the form when response includes non-form fields', async () => {
        customMetadataFields = '{}'
        let wrapper = wrapperFactory([])

        wrapper.vm.$parent.refreshCustomMetadata = jest.fn().mockResolvedValue(true)

        const customMetadataMock = jest.fn()
        customMetadataMock.mockReturnValue({ a_key_that_is_not_in_config: 'UPDATED' })
        wrapper.vm.$parent.customMetadata = customMetadataMock()

        await wrapper.vm.fetchCustomMetadata()

        expect(wrapper.vm.$parent.refreshCustomMetadata).toHaveBeenCalled()
        expect(wrapper.vm.form).toEqual({ a_key_that_is_not_in_config: 'UPDATED' })
      })

      it('does not update the form when response is empty', async () => {
        customMetadataFields = '{"RT LunaScript Super Mix":{"key":"rt_lunascript_super_mix"}}'
        let wrapper = wrapperFactory([])

        wrapper.vm.$parent.refreshCustomMetadata = jest.fn().mockResolvedValue(true)

        const customMetadataMock = jest.fn()
        customMetadataMock.mockReturnValue({})
        wrapper.vm.$parent.customMetadata = customMetadataMock()

        await wrapper.vm.fetchCustomMetadata()

        expect(wrapper.vm.$parent.refreshCustomMetadata).toHaveBeenCalled()
        expect(wrapper.vm.form).toEqual({ rt_lunascript_super_mix: '' })
      })
    })

    describe('#submit', () => {
      it('submits custom metadata via the store object without id', async () => {
        let wrapper = wrapperFactory([])

        wrapper.vm.$parent.addCustomMetadata = jest.fn().mockResolvedValue(true)
        wrapper.setData({
          form: {
            rt_lunascript_super_mix: 'avalue',
          },
        })
        expect(wrapper.vm.state).toEqual('pending')

        wrapper.vm.submit()

        expect(wrapper.vm.state).toEqual('busy')
        expect(wrapper.vm.$parent.addCustomMetadata).toHaveBeenCalledWith(undefined, {
          rt_lunascript_super_mix: 'avalue',
        })
      })

      it('submits custom metadata via the store object with id', async () => {
        customMetadatumCollectionsId = 123
        let wrapper = wrapperFactory([])

        wrapper.vm.$parent.addCustomMetadata = jest.fn().mockResolvedValue(true)
        wrapper.setData({
          form: {
            rt_lunascript_super_mix: 'avalue',
          },
        })
        expect(wrapper.vm.state).toEqual('pending')

        wrapper.vm.submit()

        expect(wrapper.vm.state).toEqual('busy')
        expect(wrapper.vm.$parent.addCustomMetadata).toHaveBeenCalledWith(123, {
          rt_lunascript_super_mix: 'avalue',
        })
      })
    })
  })
})
