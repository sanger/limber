import localVue from 'test_support/base_vue.js'
import ValidatePairedTubes from './ValidatePairedTubes.vue'
import { shallowMount } from '@vue/test-utils'

import {
  checkId,
  checkMolarityResult,
  checkPurpose,
  checkState,
  checkTransferParameters
} from 'shared/components/tubeScanValidators'
jest.mock('shared/components/tubeScanValidators')

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

  describe('purposeConfigs', () => {
    it('parses an Object from the purposeConfigJson prop', () => {
      const wrapper = wrapperFactory({ purposeConfigJson: '{"test":{"option":42}}' })
      expect(wrapper.vm.purposeConfigs).toEqual({ test: { option: 42 } })
    })
  })

  describe('validators', () => {
    const validMessage = { valid: true }
    const mockCheckState = (_) => validMessage
    const mockCheckTransferParameters = (_) => validMessage
    const mockCheckMolarityResult = (_) => validMessage
    const mockCheckPurpose = (_) => validMessage
    const mockCheckId = (_) => validMessage

    beforeEach(() => {
      checkState.mockReturnValue(mockCheckState)
      checkTransferParameters.mockReturnValue(mockCheckTransferParameters)
      checkMolarityResult.mockReturnValue(mockCheckMolarityResult)
      checkPurpose.mockReturnValue(mockCheckPurpose)
      checkId.mockReturnValue(mockCheckId)
    })

    describe('sourceTubeValidators', () => {
      it('includes the checkState validator', () => {
        const wrapper = wrapperFactory()
        expect(wrapper.vm.sourceTubeValidators).toContain(mockCheckState)
      })

      it('includes the checkTransferParameters validator', () => {
        const wrapper = wrapperFactory()
        expect(wrapper.vm.sourceTubeValidators).toContain(mockCheckTransferParameters)
      })

      it('includes the checkMolarityResult validator', () => {
        const wrapper = wrapperFactory()
        expect(wrapper.vm.sourceTubeValidators).toContain(mockCheckMolarityResult)
      })
    })

    describe('destinationTubeValidators', () => {
      it('includes the checkPurpose validator', () => {
        const wrapper = wrapperFactory()
        expect(wrapper.vm.destinationTubeValidators).toContain(mockCheckPurpose)
      })

      it('includes the checkId validator', () => {
        const wrapper = wrapperFactory()
        expect(wrapper.vm.destinationTubeValidators).toContain(mockCheckId)
      })
    })

    it('passed the correct parameter to checkState', () => {
      wrapperFactory()
      expect(checkState.mock.calls[0][0]).toEqual(['passed'])
    })

    it('passed the correct parameter to checkTransferParameters', () => {
      wrapperFactory({ purposeConfigJson: '{ "testKey": "testValue" }' })
      expect(checkTransferParameters.mock.calls[0][0]).toEqual({ testKey: 'testValue' })
    })

    it('passed the correct parameter to checkPurpose', () => {
      wrapperFactory()
      expect(checkPurpose.mock.calls[0][0]).toEqual(['LB Lib Pool Norm'])
    })

    it('passed the correct parameters to checkId', () => {
      const wrapper = wrapperFactory()

      // Before setting a source tube
      expect(checkId.mock.calls[0][0]).toEqual([])
      expect(checkId.mock.calls[0][1]).toEqual('Does not match the source tube')

      wrapper.vm.updateSourceTube({ labware: { receptacle: { downstream_tubes: [{ id: 'test1' }, { id: 'test2' }] } } })
      wrapper.vm.destinationTubeValidators  // Refresh the evaluation to cause more calls to checkId

      // After setting a source tube
      console.log(checkId.mock.calls)
      expect(checkId.mock.calls[1][0]).toEqual(['test1', 'test2'])
      expect(checkId.mock.calls[1][1]).toEqual('Does not match the source tube')
    })
  })

  describe('allValid', () => {
    it('first test', () => {
      wrapperFactory()
    })
  })

  describe('updateSourceTube', () => {
    it('first test', () => {
      wrapperFactory()
    })
  })

  describe('updateDestinationTube', () => {
    it('first test', () => {
      wrapperFactory()
    })
  })
})
