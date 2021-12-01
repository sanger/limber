import localVue from 'test_support/base_vue.js'
import TubesToRack from './TubesToRack.vue'
import { checkDuplicates, checkMatchingPurposes } from 'shared/components/tubeScanValidators'
import { shallowMount } from '@vue/test-utils'
import { tubeFactory } from 'test_support/factories'

jest.mock('shared/components/tubeScanValidators')

describe('MultiStampTubes', () => {
  const wrapperFactory = function(options = {}) {
    // Not ideal using mount here, but having massive trouble
    // triggering change events on unmounted components
    return shallowMount(TubesToRack, {
      propsData: {
        targetUrl: '',
        ...options
      },
      localVue
    })
  }

  it('disables creation if there are no tubes', () => {
    const wrapper = wrapperFactory()
    expect(wrapper.vm.valid).toEqual(false)
  })

  it('enables creation when there are all valid tubes', () => {
    const wrapper = wrapperFactory()
    const tube1 = { state: 'valid', labware: tubeFactory({ uuid: 'tube-uuid-1' }) }
    const tube2 = { state: 'valid', labware: tubeFactory({ uuid: 'tube-uuid-2' }) }

    wrapper.vm.updateTube(1, tube1)
    wrapper.vm.updateTube(2, tube2)

    expect(wrapper.vm.valid).toEqual(true)
  })

  it('disables creation when there are some invalid tubes', () => {
    const wrapper = wrapperFactory()
    const tube1 = { state: 'valid', labware: tubeFactory({ uuid: 'tube-uuid-1' }) }
    const tube2 = { state: 'invalid', labware: tubeFactory({ uuid: 'tube-uuid-2' }) }

    wrapper.vm.updateTube(1, tube1)
    wrapper.vm.updateTube(2, tube2)

    expect(wrapper.vm.valid).toEqual(false)
  })

  it('uses the checkDuplicates validator function',  async () => {
    const wrapper = wrapperFactory()
    const tube1 = { state: 'valid', labware: tubeFactory({ uuid: 'tube-uuid-1' }) }
    const tube2 = { state: 'invalid', labware: tubeFactory({ uuid: 'tube-uuid-2' }) }

    wrapper.vm.updateTube(1, tube1)
    wrapper.vm.updateTube(2, tube2)

    wrapper.vm.scanValidators

    expect(checkDuplicates).toHaveBeenLastCalledWith([
      tube1.labware, tube2.labware, null, null, null, null, null, null,
      null, null, null, null, null, null, null, null
    ]) // 16 values in total
  })

  it('uses the checkMatchingPurposes validator function',  async () => {
    const wrapper = wrapperFactory()
    const tube1 = { state: 'valid', labware: tubeFactory({ uuid: 'tube-uuid-1' }) }
    const tube2 = { state: 'invalid', labware: tubeFactory({ uuid: 'tube-uuid-2' }) }

    wrapper.vm.updateTube(1, tube1)
    wrapper.vm.updateTube(2, tube2)

    wrapper.vm.scanValidators

    expect(checkMatchingPurposes).toHaveBeenLastCalledWith(tube1.labware.purpose)
  })
})
