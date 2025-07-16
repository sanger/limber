import { mount } from '@vue/test-utils'
import VolumeTransfers from './VolumeTransfers.vue'

describe('VolumeTransfers', () => {
  const wrapperFactory = function () {
    return mount(VolumeTransfers, {
      props: {
        validTransfers: [],
      },
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
    wrapper.find('#input-volume').setValue('40')

    await wrapper.vm.$nextTick()

    const emittedEvents = wrapper.emitted()['update:model-value']
    expect(emittedEvents).toBeTruthy()
    expect(emittedEvents.length).toEqual(1)

    expect(emittedEvents[0][0].isValid).toEqual(true)
    // This is not a nice way to check the events but because extraParams passes a function reference
    // It is easier to compare the output of the function rather than comparing the function references are the same
    // Because this causes issues with the test comparison
    expect(emittedEvents[0][0].extraParams()).toEqual(wrapper.vm.transferFunc())
  })
})
