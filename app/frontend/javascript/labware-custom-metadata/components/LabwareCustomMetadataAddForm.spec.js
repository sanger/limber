import { flushPromises } from '@vue/test-utils'
import { mount } from '@vue/test-utils'
import LabwareCustomMetadataAddForm from './LabwareCustomMetadataAddForm.vue'

describe('LabwareCustomMetadataAddForm', () => {
  let customMetadataFields = '[]'
  let labwareId = '123'
  let userId = '456'
  let sequencescapeApi = 'http://example.com/v2'
  let sequencescapeUrl = 'http://example.com'
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

    global.fetch = vi.fn().mockReturnValue(
      Promise.resolve({
        json: () => Promise.resolve(data),
      }),
    )

    // This is a workaround for the following warning:
    // [BootstrapVue warn]: tooltip - The provided target is no valid HTML element.
    const createContainer = (tag = 'div') => {
      const container = document.createElement(tag)
      document.body.appendChild(container)

      return container
    }

    return mount(LabwareCustomMetadataAddForm, {
      attachTo: createContainer(),
      parentComponent: parent,
      props: {
        customMetadataFields,
        labwareId,
        userId,
        sequencescapeApi,
        sequencescapeUrl,
      },
    })
  }

  describe('#form', () => {
    describe('when customMetadataFields is empty', () => {
      it('does not render the form or the button', () => {
        customMetadataFields = '[]'
        let wrapper = wrapperFactory()

        expect(wrapper.find('#custom-metadata-input-form').exists()).toBe(false)
        expect(wrapper.find('#labware_custom_metadata_submit_button').exists()).toBe(false)
      })
    })

    describe('when customMetadataFields is not empty', () => {
      it('renders a form, with the correct inputs, and the create button', () => {
        customMetadataFields = '["RT LunaScript Super Mix","RT NFW","RT DFD Syringe Lot Number"]'
        let wrapper = wrapperFactory()

        expect(wrapper.find('#custom-metadata-input-form').exists()).toBe(true)
        // expect(wrapper.find('RT LunaScript Super Mix').exists()).toBe(true)
        // expect(wrapper.find('#RT NFW').exists()).toBe(true)
        // expect(wrapper.find('#RT DFD Syringe Lot Number').exists()).toBe(true)
        expect(wrapper.find('#labware_custom_metadata_submit_button').exists()).toBe(true)
        expect(wrapper.find('#labware_custom_metadata_submit_button').text()).toEqual(
          'Add Custom Metadata to Sequencescape',
        )
      })
    })
  })

  describe('props', () => {
    it('can be passed', () => {
      let wrapper = wrapperFactory({})
      expect(wrapper.vm.customMetadataFields).toEqual(customMetadataFields)
      expect(wrapper.vm.labwareId).toEqual(labwareId)
      expect(wrapper.vm.sequencescapeApi).toEqual(sequencescapeApi)
      expect(wrapper.vm.userId).toEqual(userId)
    })
  })

  describe('#data', () => {
    it('is initialised', () => {
      customMetadataFields = '["RT LunaScript Super Mix","RT NFW","RT DFD Syringe Lot Number"]'
      let wrapper = wrapperFactory()

      expect(wrapper.vm.state).toBe('pending')
      expect(wrapper.vm.form).toStrictEqual({
        'RT LunaScript Super Mix': '',
        'RT NFW': '',
        'RT DFD Syringe Lot Number': '',
      })
      let expectedNormalisedFields = ['RT LunaScript Super Mix', 'RT NFW', 'RT DFD Syringe Lot Number']
      expect(wrapper.vm.normalizedFields).toEqual(expectedNormalisedFields)
      expect(wrapper.vm.customMetadatumCollectionsId).toEqual(undefined)
    })
  })

  describe('#computed', () => {
    it('customMetadataFieldsExist', () => {
      customMetadataFields = '["RT LunaScript Super Mix","RT NFW","RT DFD Syringe Lot Number"]'
      let wrapper = wrapperFactory()
      expect(wrapper.vm.customMetadataFieldsExist).toEqual(true)

      customMetadataFields = '[]'
      wrapper = wrapperFactory()
      expect(wrapper.vm.customMetadataFieldsExist).toEqual(false)
    })
  })

  describe('#mounted', () => {
    describe('#setupForm', () => {
      it('correctly sets the form to empty when no fields exist', () => {
        customMetadataFields = '[]'
        let wrapper = wrapperFactory()
        expect(wrapper.vm.form).toStrictEqual({})
      })

      it('correctly sets the form when fields exist', () => {
        customMetadataFields = '["RT LunaScript Super Mix","RT NFW","RT DFD Syringe Lot Number"]'
        let wrapper = wrapperFactory()

        let expected = {
          'RT LunaScript Super Mix': '',
          'RT NFW': '',
          'RT DFD Syringe Lot Number': '',
        }
        expect(wrapper.vm.form).toStrictEqual(expected)
      })
    })

    describe('#fetchCustomMetadata', () => {
      it('updates the form, when there is config and matching data', async () => {
        customMetadataFields = '["RT LunaScript Super Mix"]'

        mockFetchData = {
          included: [{ id: labwareId, attributes: { metadata: { 'RT LunaScript Super Mix': 'a value' } } }],
        }
        let wrapper = wrapperFactory(mockFetchData)

        await flushPromises()

        expect(global.fetch).toHaveBeenCalledTimes(1)

        expect(wrapper.vm.customMetadatumCollectionsId).toEqual(labwareId)
        expect(wrapper.vm.form).toEqual({ 'RT LunaScript Super Mix': 'a value' })
      })

      it('updates the form, when there is config and no data', async () => {
        customMetadataFields = '["RT LunaScript Super Mix"]'

        mockFetchData = {}
        let wrapper = wrapperFactory(mockFetchData)

        await flushPromises()

        expect(global.fetch).toHaveBeenCalledTimes(1)

        expect(wrapper.vm.customMetadatumCollectionsId).toEqual(undefined)
        expect(wrapper.vm.form).toEqual({ 'RT LunaScript Super Mix': '' })
      })

      it('updates the form, when there is no config and some data', async () => {
        customMetadataFields = '[]'

        mockFetchData = {
          included: [{ id: labwareId, attributes: { metadata: { a_value_that_is_not_config: 'a value' } } }],
        }
        let wrapper = wrapperFactory(mockFetchData)

        await flushPromises()

        expect(global.fetch).toHaveBeenCalledTimes(1)

        expect(wrapper.vm.customMetadatumCollectionsId).toEqual(labwareId)
        expect(wrapper.vm.form).toEqual({ a_value_that_is_not_config: 'a value' })
      })

      it('updates the form, when there is config and some matching data', async () => {
        customMetadataFields = '["RT LunaScript Super Mix"]'

        mockFetchData = {
          included: [
            {
              id: labwareId,
              attributes: { metadata: { a_value_that_is_not_config: 'a value' } },
            },
          ],
        }
        let wrapper = wrapperFactory(mockFetchData)

        await flushPromises()

        expect(global.fetch).toHaveBeenCalledTimes(1)

        expect(wrapper.vm.customMetadatumCollectionsId).toEqual(labwareId)
        expect(wrapper.vm.form).toEqual({ 'RT LunaScript Super Mix': '', a_value_that_is_not_config: 'a value' })
      })
    })
  })

  describe('#methods', () => {
    describe('#onUpdate', () => {
      it('sets state to pending if it isnt already', () => {
        customMetadataFields = '[]'
        let wrapper = wrapperFactory()
        wrapper.vm.state = 'busy'
        wrapper.vm.onUpdate()
        expect(wrapper.vm.state).toEqual('pending')
      })
    })

    describe('#submit', () => {
      it('trims data', () => {
        let wrapper = wrapperFactory()
        wrapper.vm.postData = vi.fn()

        wrapper.setData({
          form: {
            'RT LunaScript Super Mix': 'avalue    ',
            an_emtpy_value: '    ',
          },
        })

        wrapper.vm.submit()
        expect(wrapper.vm.state).toEqual('busy')
        expect(wrapper.vm.postData).toHaveBeenCalledTimes(1)
        expect(wrapper.vm.postData).toHaveBeenCalledWith({ 'RT LunaScript Super Mix': 'avalue' })
      })

      it('calls postData', () => {
        let wrapper = wrapperFactory()
        wrapper.vm.postData = vi.fn()

        wrapper.setData({
          form: {
            'RT LunaScript Super Mix': 'avalue',
            an_emtpy_value: '',
            'A previously existing field': 'robot1',
          },
        })

        wrapper.vm.submit()
        expect(wrapper.vm.state).toEqual('busy')
        expect(wrapper.vm.postData).toHaveBeenCalledTimes(1)
        expect(wrapper.vm.postData).toHaveBeenCalledWith({
          'RT LunaScript Super Mix': 'avalue',
          'A previously existing field': 'robot1',
        })
      })
    })

    describe('#postData', () => {
      it('creates a PATCH request', async () => {
        mockFetchData = { data: { id: labwareId } }
        let wrapper = wrapperFactory(mockFetchData)

        wrapper.vm.refreshCustomMetadata = vi.fn()

        wrapper.setData({
          customMetadatumCollectionsId: labwareId,
        })

        wrapper.vm.postData({ 'RT LunaScript Super Mix': 'avalue' })

        await flushPromises()

        expect(global.fetch).toHaveBeenCalledTimes(2) // 1 on mount
        expect(wrapper.vm.customMetadatumCollectionsId).toEqual(labwareId)
        expect(wrapper.vm.state).toEqual('success')
      })

      it('creates a POST request', async () => {
        mockFetchData = { data: { id: labwareId } }
        let wrapper = wrapperFactory(mockFetchData)

        wrapper.vm.refreshCustomMetadata = vi.fn()

        wrapper.vm.postData({ 'RT LunaScript Super Mix': 'avalue' })

        await flushPromises()

        expect(global.fetch).toHaveBeenCalledTimes(2) // 1 on mount
        expect(wrapper.vm.customMetadatumCollectionsId).toEqual(labwareId)
        expect(wrapper.vm.state).toEqual('success')
      })
    })

    // TODO: Y24-248 - add this test suite
    // describe('#buildPayload', () => {
    // })
  })
})
