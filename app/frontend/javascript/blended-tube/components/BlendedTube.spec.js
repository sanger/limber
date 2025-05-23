// Import the component being tested
import { shallowMount } from '@vue/test-utils'
import BlendedTube from '@/javascript/blended-tube/components/BlendedTube.vue'
import mockApi from '@/javascript/test_support/mock_api.js'

// create an extended `Vue` constructor
import localVue from '@/javascript/test_support/base_vue.js'

import MockAdapter from 'axios-mock-adapter'
import flushPromises from 'flush-promises' // Add this import for handling asynchronous updates

describe('BlendedTube.vue', () => {
  let wrapper
  let mockAxios
  let mockLocation

  const wrapperFactory = (options = {}) => {
    return shallowMount(BlendedTube, {
      propsData: {
        childPurposeUuid: 'child-purpose-uuid',
        childPurposeName: 'Child Purpose',
        targetUrl: '/api/tubes',
        ancestorLabwarePurposeName: 'Ancestor Purpose',
        acceptableParentTubePurposes: JSON.stringify(['Purpose 1', 'Purpose 2']),
        locationObj: mockLocation, // Use the mock location object
        api: mockApi().devour,
        ...options,
      },
      localVue,
    })
  }

  beforeEach(() => {
    mockAxios = new MockAdapter(localVue.prototype.$axios)
    mockLocation = { href: '' } // Initialize mock location object
    wrapper = wrapperFactory()
  })

  afterEach(() => {
    mockAxios.restore()
    wrapper.destroy()
  })

  it('renders correctly with required props', () => {
    expect(wrapper.find('b-card-stub').attributes('header')).toBe('Blend Tubes:')
    expect(wrapper.find('b-button-stub').text()).toBe('Blend')
  })

  it('disables the Blend button when pairing is invalid', async () => {
    await wrapper.setData({ isPairingValid: false })
    expect(wrapper.find('b-button-stub').attributes('disabled')).toBe('true')
  })

  it('enables the Blend button when pairing is valid', async () => {
    await wrapper.setData({ isPairingValid: true })
    expect(wrapper.find('b-button-stub').attributes('disabled')).toBeUndefined()
  })

  it('updates tube pairing state on updateTubePair method call', async () => {
    const data = {
      state: 'valid',
      pairedTubes: [{ labware: { uuid: 'tube-uuid-1' } }, { labware: { uuid: 'tube-uuid-2' } }],
    }
    wrapper.vm.updateTubePair(data)
    await wrapper.vm.$nextTick()
    expect(wrapper.vm.isPairingValid).toBe(true)
    expect(wrapper.vm.parentTubes).toEqual([{ uuid: 'tube-uuid-1' }, { uuid: 'tube-uuid-2' }])
  })

  it('handles createTube method successfully', async () => {
    mockAxios.onPost('/api/tubes').reply(201, { message: 'Success', redirect: '/new-url' })

    wrapper.vm.parentTubes = [{ uuid: 'tube-uuid-1' }, { uuid: 'tube-uuid-2' }]
    wrapper.vm.isPairingValid = true

    wrapper.vm.createTube()
    expect(wrapper.vm.progressMessage).toBe('Creating blended tube...')
    expect(wrapper.vm.loading).toBe(true)

    await flushPromises() // Wait for all promises to resolve
    expect(wrapper.vm.progressMessage).toBe('Success')
    expect(mockLocation.href).toBe('/new-url') // Assert the mock location object
  })

  it('handles createTube method failure', async () => {
    mockAxios.onPost('/api/tubes').reply(500, { message: 'Error' })

    wrapper.vm.parentTubes = [{ uuid: 'tube-uuid-1' }, { uuid: 'tube-uuid-2' }]
    wrapper.vm.isPairingValid = true

    wrapper.vm.createTube()
    expect(wrapper.vm.loading).toBe(true) // Ensure loading is true initially

    await flushPromises() // Wait for all promises to resolve

    expect(wrapper.vm.loading).toBe(false) // Ensure loading is reset to false after failure
  })
})
