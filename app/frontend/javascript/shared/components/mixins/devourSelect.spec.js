import Vue from 'vue'
import DevourSelect from '@/javascript/shared/components/mixins/devourSelect.js'
import { mount } from '@vue/test-utils'
import flushPromises from 'flush-promises'
import mockApi from '@/javascript/test_support/mock_api.js'
import localVue from '@/javascript/test_support/base_vue.js'

describe('DevourSelect mixin', () => {
  const testResourceName = 'test'
  const testValidation = (_) => {
    return { valid: true, message: 'Good' }
  }
  const testValidationApiError = (_) => {
    return { valid: false, message: 'Unknown error' }
  }
  const testIncludes = 'test'
  const testFilter = { uuid: 1 }
  const testFields = { tests: 'uuid,description' }
  let cmp, devourSelectInstance, data

  beforeEach(() => {
    data = {
      api: {},
      resourceName: testResourceName,
      includes: testIncludes,
      filter: testFilter,
      fields: testFields,
      validation: testValidation,
    }
    cmp = Vue.extend({ mixins: [DevourSelect] }) // eslint-disable-line vue/one-component-per-file
    devourSelectInstance = new cmp({
      propsData: data,
    })
  })

  describe('checking props:', () => {
    it('has an api', () => {
      expect(devourSelectInstance.api).toEqual(data.api)
    })

    it('has a resource name', () => {
      expect(devourSelectInstance.resourceName).toEqual(testResourceName)
    })

    it('has an includes', () => {
      expect(devourSelectInstance.includes).toEqual(testIncludes)
    })

    it('has a filter', () => {
      expect(devourSelectInstance.filter).toEqual(testFilter)
    })

    it('has a fields', () => {
      expect(devourSelectInstance.fields).toEqual(testFields)
    })

    it('has a validation', () => {
      expect(devourSelectInstance.validation).toEqual(testValidation)
    })
  })

  describe('checking api behaviour', () => {
    const wrapperFactory = function (api = mockApi()) {
      const MyComponent = Vue.extend({ mixins: [DevourSelect] }) // eslint-disable-line vue/one-component-per-file
      return mount(MyComponent, {
        propsData: {
          api: api.devour,
          resourceName: testResourceName,
          includes: testIncludes,
          filter: testFilter,
          fields: testFields,
          validation: testValidationApiError,
        },
        localVue,
      })
    }

    it('is invalid if there are api troubles', async () => {
      const api = mockApi()

      // Devour logs the error automatically, which clutters the feedback
      // so we disable logging here
      vi.spyOn(console, 'log').mockImplementation(() => {})

      // mock the devour api: url, params, response
      api.mockFail(
        'tests',
        {
          filter: testFilter,
          include: testIncludes,
          fields: testFields,
        },
        {
          errors: [
            {
              title: 'Not good',
              detail: 'Very not good',
              code: 500,
              status: 500,
            },
          ],
        },
      )

      const wrapper = wrapperFactory(api)
      wrapper.vm.performLookup()

      expect(wrapper.vm.state).toEqual('searching')

      await flushPromises()

      expect(wrapper.vm.feedback).toEqual('Not good: Very not good')
      expect(wrapper.emitted()).toEqual({
        change: [[{ state: 'invalid', results: null }]],
      })
    })
  })
})
