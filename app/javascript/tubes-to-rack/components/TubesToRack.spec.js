import { shallowMount } from '@vue/test-utils'
import TubesToRack from './TubesToRack.vue'
import localVue from 'test_support/base_vue.js'

describe('MultiStampTubes', () => {
  const wrapperFactory = function(options = {}) {
    // Not ideal using mount here, but having massive trouble
    // triggering change events on unmounted components
    return shallowMount(TubesToRack, {
      propsData: { ...options },
      localVue
    })
  }

  it('disables creation if there are no tubes', () => {
    const wrapper = wrapperFactory()

    expect(wrapper.vm.valid).toEqual(false)
  })
})
