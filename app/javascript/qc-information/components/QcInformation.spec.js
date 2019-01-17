// Import the component being tested
import { shallowMount } from '@vue/test-utils'
import localVue from 'test_support/base_vue.js'

import QcInformation from './QcInformation.vue'
// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
describe('QcInformation', () => {
  const wrapperFactory = function() {
    return shallowMount(QcInformation, {
      propsData: {
        assetUuid: 'test'
      },
      localVue
    })
  }

  it('updates its data as values change', () => {
    let wrapper = wrapperFactory()

    let volumeAttributes = { value: '1.5', assay_type: 'Volume Check', units: 'ul', key: 'volume', assay_version: 'manual' }
    let molarityAttributes = { value: '10', assay_type: 'Estimated', units: 'nM', key: 'molarity', assay_version: 'manual' }
    wrapper.find('lb-qc-field-stub[name="volume"]').vm.$emit('change', volumeAttributes)
    wrapper.find('lb-qc-field-stub[name="molarity"]').vm.$emit('change', molarityAttributes)

    expect(wrapper.vm.qcResults.volume).toEqual(volumeAttributes)
    expect(wrapper.vm.qcResults.molarity).toEqual(molarityAttributes)
  })

  it('filters empty values', () => {
    let wrapper = wrapperFactory()
    let fullAttributes = { value: '1.5', assay_type: 'Volume Check', units: 'ul', key: 'volume', assay_version: 'manual' }
    let emptyAttributes = { value: '', assay_type: 'Estimated', units: 'nM', key: 'molarity', assay_version: 'manual' }
    wrapper.setData({ qcResults: { volume: fullAttributes, molarity: emptyAttributes } })
    expect(wrapper.vm.filledQcResults).toEqual([fullAttributes])
  })

  it('submits a qc result on click', () => {
    let wrapper = wrapperFactory()
    let fullAttributes = { value: '1.5', assay_type: 'Volume Check', units: 'ul', key: 'volume', assay_version: 'manual' }
    let emptyAttributes = { value: '', assay_type: 'Estimated', units: 'nM', key: 'molarity', assay_version: 'manual' }
    wrapper.setData({ qcResults: { volume: fullAttributes, molarity: emptyAttributes } })

    expect(wrapper.vm.qcAssay.qcResults).toEqual([fullAttributes])
    spyOn(wrapper.vm.qcAssay, 'save')
    // Triggering events on bootstrap stuff is currently unnecessarily painful
    wrapper.vm.submit()
    expect(wrapper.vm.qcAssay.save).toHaveBeenCalled()
  })
})
