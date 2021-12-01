import localVue from 'test_support/base_vue.js'
import ValidatePairedTubes from './ValidatePairedTubes.vue'
import { shallowMount } from '@vue/test-utils'

describe('TransferVolumes', () => {
  const wrapperFactory = function(options = {}) {
    const LabwareScan = {
      template: '<div />',
      methods: {
        focus() { }
      }
    }

    return shallowMount(ValidatePairedTubes, {
      stubs: {
        'lb-labware-scan': LabwareScan
      },
      propsData: {
        purposeConfigJson: '{}',
        ...options
      },
      localVue
    })
  }

  it('first test', () => {
    wrapperFactory()
  })
})
