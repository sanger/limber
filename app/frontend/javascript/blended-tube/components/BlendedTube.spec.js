// Import the component being tested
import { mount, flushPromises } from '@vue/test-utils'
import BlendedTube from '@/javascript/blended-tube/components/BlendedTube.vue'
import mockApi from '@/javascript/test_support/mock_api.js'

describe('BlendedTube.vue', () => {
  let wrapper
  let mockLocation = {}

  const wrapperFactory = (options = {}) => {
    return mount(BlendedTube, {
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
    })
  }

  beforeEach(() => {
    wrapper = wrapperFactory()
  })

  it('renders correctly with required props', () => {
    expect(wrapper.find('.card-header').text()).toBe('Blend Tubes:')
    expect(wrapper.find('button').text()).toBe('Blend')
  })

  it('disables the Blend button when pairing is invalid', async () => {
    await wrapper.setData({ isPairingValid: false })
    expect(wrapper.find('button').isDisabled()).toBe(true)
  })

  it('enables the Blend button when pairing is valid', async () => {
    await wrapper.setData({ isPairingValid: true })
    expect(wrapper.find('button').isDisabled()).toBe(false)
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
    mockLocation.href = null
    wrapper.vm.$axios = vi.fn().mockResolvedValue({ data: { message: 'Success', redirect: '/new-url' } })

    wrapper.vm.parentTubes = [{ uuid: 'tube-uuid-1' }, { uuid: 'tube-uuid-2' }]
    wrapper.vm.isPairingValid = true

    wrapper.vm.createTube()
    expect(wrapper.vm.progressMessage).toBe('Creating blended tube...')
    expect(wrapper.vm.loading).toBe(true)

    await flushPromises() // Wait for all promises to resolve
    expect(wrapper.vm.progressMessage).toBe('Success')
    expect(mockLocation.href).toBe('/new-url') // Assert the mock location object
    expect(wrapper.vm.$axios).toHaveBeenCalledTimes(1)
    expect(wrapper.vm.$axios).toHaveBeenCalledWith(
      expect.objectContaining({
        method: 'post',
        url: '/api/tubes',
        headers: { 'X-Requested-With': 'XMLHttpRequest' },
        data: {
          tube: {
            parent_uuid: wrapper.vm.parentTubes[0].uuid,
            purpose_uuid: wrapper.vm.childPurposeUuid,
            transfers: wrapper.vm.apiTransfers(),
          },
        },
      }),
    )
  })

  it('handles createTube method failure', async () => {
    mockLocation.href = null
    wrapper.vm.$axios = vi.fn().mockRejectedValue({ data: { message: 'Error' } })

    wrapper.vm.parentTubes = [{ uuid: 'tube-uuid-1' }, { uuid: 'tube-uuid-2' }]
    wrapper.vm.isPairingValid = true

    wrapper.vm.createTube()
    expect(wrapper.vm.loading).toBe(true) // Ensure loading is true initially

    await flushPromises() // Wait for all promises to resolve

    expect(wrapper.vm.loading).toBe(false) // Ensure loading is reset to false after failure
    expect(wrapper.vm.$axios).toHaveBeenCalledTimes(1)
    expect(wrapper.vm.$axios).toHaveBeenCalledWith(
      expect.objectContaining({
        method: 'post',
        url: '/api/tubes',
        headers: { 'X-Requested-With': 'XMLHttpRequest' },
        data: {
          tube: {
            parent_uuid: wrapper.vm.parentTubes[0].uuid,
            purpose_uuid: wrapper.vm.childPurposeUuid,
            transfers: wrapper.vm.apiTransfers(),
          },
        },
      }),
    )
  })
})
