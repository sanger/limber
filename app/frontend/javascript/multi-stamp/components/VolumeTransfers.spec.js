import { shallowMount } from '@vue/test-utils'
import VolumeTransfers from './VolumeTransfers.vue'
import localVue from 'test_support/base_vue.js'

describe('VolumeTransfers', () => {
  const wrapperFactory = function () {
    return shallowMount(VolumeTransfers, {
      propsData: {
        validTransfers: [],
      },
      localVue,
    })
  }

  it('returns extraParams function containing volume value', () => {
    const wrapper = wrapperFactory()
    wrapper.setData({ volume: '40' })

    expect(wrapper.vm.transferFunc()).toEqual({ volume: '40' })
  })

  it('isValid === true, when volume is a number', () => {
    const wrapper = wrapperFactory()
    wrapper.setData({ volume: '40' })

    expect(wrapper.vm.isValid).toEqual(true)
  })

  it('isValid === false, when volume is not a number', () => {
    const wrapper = wrapperFactory()
    wrapper.setData({ volume: 'bla' })

    expect(wrapper.vm.isValid).toEqual(false)
  })

  it('emits the correct composite object', async () => {
    const wrapper = wrapperFactory()
    wrapper.setData({ volume: '40' })

    await wrapper.vm.$nextTick()

    expect(wrapper.emitted()).toEqual({
      change: [
        [
          {
            isValid: true,
            extraParams: wrapper.vm.transferFunc,
          },
        ],
      ],
    })
  })
})
