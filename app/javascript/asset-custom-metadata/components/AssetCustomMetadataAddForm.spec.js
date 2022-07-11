import flushPromises from 'flush-promises'
import localVue from 'test_support/base_vue'
import { mount } from '@vue/test-utils'
import AssetCustomMetadataAddForm from './AssetCustomMetadataAddForm.vue'

describe('AssetCustomMetadataAddForm', () => {
  let customMetadataFields = '{}'
  let assetId = '123'
  let userId = '456'
  let sequencescapeApiUrl = 'http://example.com/v2'
  let customMetadata = {}
  let customMetadatumCollectionsId
  let mockFetchData = {}

  const wrapperFactory = function (data) {
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

    global.fetch = jest.fn().mockReturnValue(
      Promise.resolve({
        json: () => Promise.resolve(data),
      })
    )

    return mount(AssetCustomMetadataAddForm, {
      localVue,
      parentComponent: parent,
      propsData: {
        customMetadataFields,
        assetId,
        userId,
        sequencescapeApiUrl,
      },
    })
  }

  describe('#form', () => {
    describe('when customMetadataFields is empty', () => {
      it('does not render the form or the button', () => {
        customMetadataFields = '{}'
        let wrapper = wrapperFactory()

        expect(wrapper.find('#custom-metadata-input-form').exists()).toBe(false)
        expect(wrapper.find('#asset_custom_metadata_submit_button').exists()).toBe(false)
      })
    })

    describe('when customMetadataFields is not empty', () => {
      it('renders a form, with the correct inputs, and the create button', () => {
        customMetadataFields =
          '{"RT LunaScript Super Mix":{"key":"rt_lunascript_super_mix"},"RT NFW":{"key":"rt_nfw"},"RT DFD Syringe Lot Number":{"key":"rt_dfd_syringe_lot_number"}}'
        let wrapper = wrapperFactory()

        expect(wrapper.find('#custom-metadata-input-form').exists()).toBe(true)
        expect(wrapper.find('#rt_lunascript_super_mix').exists()).toBe(true)
        expect(wrapper.find('#rt_dfd_syringe_lot_number').exists()).toBe(true)

        expect(wrapper.find('#asset_custom_metadata_submit_button').exists()).toBe(true)
        expect(wrapper.find('#asset_custom_metadata_submit_button').text()).toEqual(
          'Add Custom Metadata to Sequencescape'
        )
      })
    })

    // form only shows config fields
  })

  describe('props', () => {
    it('can be passed', () => {
      let wrapper = wrapperFactory({})
      expect(wrapper.vm.customMetadataFields).toEqual(customMetadataFields)
      expect(wrapper.vm.assetId).toEqual(assetId)
      expect(wrapper.vm.sequencescapeApiUrl).toEqual(sequencescapeApiUrl)
      expect(wrapper.vm.userId).toEqual(userId)
    })
  })

  describe('#data', () => {
    it('is initialised', () => {
      customMetadataFields = '{"RT LunaScript Super Mix":{"key":"rt_lunascript_super_mix"}}'
      let wrapper = wrapperFactory()

      expect(wrapper.vm.state).toBe('pending')
      expect(wrapper.vm.form).toStrictEqual({ rt_lunascript_super_mix: '' })
      let expectedNormalisedFields = { 'RT LunaScript Super Mix': { key: 'rt_lunascript_super_mix' } }
      expect(wrapper.vm.normalizedFields).toEqual(expectedNormalisedFields)
      expect(wrapper.vm.customMetadatumCollectionsId).toEqual(undefined)
    })
  })

  describe('#computed', () => {
    it('customMetadataFieldsExist', () => {
      customMetadataFields =
        '{"RT LunaScript Super Mix":{"key":"rt_lunascript_super_mix"},"RT NFW":{"key":"rt_nfw"},"RT DFD Syringe Lot Number":{"key":"rt_dfd_syringe_lot_number"}}'
      let wrapper = wrapperFactory()
      expect(wrapper.vm.customMetadataFieldsExist).toEqual(true)

      customMetadataFields = '{}'
      wrapper = wrapperFactory()
      expect(wrapper.vm.customMetadataFieldsExist).toEqual(false)
    })
  })

  describe('#mounted', () => {
    describe('#setupForm', () => {
      it('correctly sets the form to empty when no fields exist', () => {
        customMetadataFields = '{}'
        let wrapper = wrapperFactory()
        expect(wrapper.vm.form).toStrictEqual({})
      })

      it('correctly sets the form when fields exist', () => {
        customMetadataFields =
          '{"RT LunaScript Super Mix":{"key":"rt_lunascript_super_mix"},"RT NFW":{"key":"rt_nfw"},"RT DFD Syringe Lot Number":{"key":"rt_dfd_syringe_lot_number"}}'
        let wrapper = wrapperFactory()

        let expected = {
          rt_dfd_syringe_lot_number: '',
          rt_lunascript_super_mix: '',
          rt_nfw: '',
        }
        expect(wrapper.vm.form).toStrictEqual(expected)
      })
    })

    describe('#fetchCustomMetadata', () => {
      it('updates the form, when there is config and matching data', async () => {
        customMetadataFields = '{"RT LunaScript Super Mix":{"key":"rt_lunascript_super_mix"}}'

        mockFetchData = {
          included: [{ id: assetId, attributes: { metadata: { rt_lunascript_super_mix: 'a value' } } }],
        }
        let wrapper = wrapperFactory(mockFetchData)

        await flushPromises()

        expect(global.fetch).toHaveBeenCalledTimes(1)

        expect(wrapper.vm.customMetadatumCollectionsId).toEqual(assetId)
        expect(wrapper.vm.form).toEqual({ rt_lunascript_super_mix: 'a value' })
      })

      it('updates the form, when there is config and no data', async () => {
        customMetadataFields = '{"RT LunaScript Super Mix":{"key":"rt_lunascript_super_mix"}}'

        mockFetchData = {}
        let wrapper = wrapperFactory(mockFetchData)

        await flushPromises()

        expect(global.fetch).toHaveBeenCalledTimes(1)

        expect(wrapper.vm.customMetadatumCollectionsId).toEqual(undefined)
        expect(wrapper.vm.form).toEqual({ rt_lunascript_super_mix: '' })
      })

      it('updates the form, when there is no config and some data', async () => {
        customMetadataFields = '{}'

        mockFetchData = {
          included: [{ id: assetId, attributes: { metadata: { a_value_that_is_not_config: 'a value' } } }],
        }
        let wrapper = wrapperFactory(mockFetchData)

        await flushPromises()

        expect(global.fetch).toHaveBeenCalledTimes(1)

        expect(wrapper.vm.customMetadatumCollectionsId).toEqual(assetId)
        expect(wrapper.vm.form).toEqual({ a_value_that_is_not_config: 'a value' })
      })

      it('updates the form, when there is config and some matching data', async () => {
        customMetadataFields = '{"RT LunaScript Super Mix":{"key":"rt_lunascript_super_mix"}}'

        mockFetchData = {
          included: [
            {
              id: assetId,
              attributes: { metadata: { a_value_that_is_not_config: 'a value' } },
            },
          ],
        }
        let wrapper = wrapperFactory(mockFetchData)

        await flushPromises()

        expect(global.fetch).toHaveBeenCalledTimes(1)

        expect(wrapper.vm.customMetadatumCollectionsId).toEqual(assetId)
        expect(wrapper.vm.form).toEqual({ rt_lunascript_super_mix: '', a_value_that_is_not_config: 'a value' })
      })
    })
  })

  describe('#methods', () => {
    describe('#onUpdate', () => {
      it('sets state to pending if it isnt already', () => {
        customMetadataFields = '{}'
        let wrapper = wrapperFactory()
        wrapper.vm.state = 'busy'
        wrapper.vm.onUpdate()
        expect(wrapper.vm.state).toEqual('pending')
      })
    })

    describe('#submit', () => {
      it('calls postData', () => {
        let wrapper = wrapperFactory()
        wrapper.vm.postData = jest.fn()

        wrapper.setData({
          form: {
            rt_lunascript_super_mix: 'avalue',
            an_emtpy_value: '',
          },
        })

        wrapper.vm.submit()
        expect(wrapper.vm.state).toEqual('busy')
        expect(wrapper.vm.postData).toHaveBeenCalledTimes(1)
        expect(wrapper.vm.postData).toHaveBeenCalledWith({ rt_lunascript_super_mix: 'avalue' })
      })
    })

    describe('#postData', () => {
      it('creates a PATCH request', async () => {
        mockFetchData = { data: { id: assetId } }
        let wrapper = wrapperFactory(mockFetchData)

        wrapper.vm.refreshCustomMetadata = jest.fn()

        wrapper.setData({
          customMetadatumCollectionsId: assetId,
        })

        wrapper.vm.postData({ rt_lunascript_super_mix: 'avalue' })

        await flushPromises()

        expect(global.fetch).toHaveBeenCalledTimes(2) // 1 on mount
        expect(wrapper.vm.customMetadatumCollectionsId).toEqual(assetId)
        expect(wrapper.vm.state).toEqual('success')
      })

      it('creates a POST request', async () => {
        mockFetchData = { data: { id: assetId } }
        let wrapper = wrapperFactory(mockFetchData)

        wrapper.vm.refreshCustomMetadata = jest.fn()

        wrapper.vm.postData({ rt_lunascript_super_mix: 'avalue' })

        await flushPromises()

        expect(global.fetch).toHaveBeenCalledTimes(2) // 1 on mount
        expect(wrapper.vm.customMetadatumCollectionsId).toEqual(assetId)
        expect(wrapper.vm.state).toEqual('success')
      })
    })

    describe('#addCustomMetadata', () => {
      it('updates the form, when there is config and some matching data', async () => {
        customMetadataFields = '{"RT LunaScript Super Mix":{"key":"rt_lunascript_super_mix"}}'

        mockFetchData = {
          included: [
            {
              id: assetId,
              attributes: { metadata: { a_value_that_is_not_config: 'a value' } },
            },
          ],
        }
        let wrapper = wrapperFactory(mockFetchData)

        await flushPromises()

        expect(global.fetch).toHaveBeenCalledTimes(1)

        expect(wrapper.vm.customMetadatumCollectionsId).toEqual(assetId)
        expect(wrapper.vm.form).toEqual({ rt_lunascript_super_mix: '', a_value_that_is_not_config: 'a value' })
      })
    })
  })
})
