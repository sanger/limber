import ValidatePairedTubes from './ValidatePairedTubes.vue'
import { mount } from '@vue/test-utils'

import {
  checkId,
  checkMolarityResult,
  checkState,
  checkTransferParameters,
} from '@/javascript/shared/components/tubeScanValidators'
vi.mock('@/javascript/shared/components/tubeScanValidators')

describe('TransferVolumes', () => {
  const wrapperFactory = function (options = {}) {
    const LabwareScan = {
      template: '<div />',
      methods: {
        focus() {},
      },
    }

    return mount(ValidatePairedTubes, {
      stubs: {
        'lb-labware-scan': LabwareScan,
      },
      props: {
        purposeConfigJson: '{}',
        ...options,
      },
    })
  }

  describe('purposeConfigs', () => {
    it('parses an Object from the purposeConfigJson prop', () => {
      const wrapper = wrapperFactory({
        purposeConfigJson: '{"test":{"option":42}}',
      })
      expect(wrapper.vm.purposeConfigs).toEqual({ test: { option: 42 } })
    })
  })

  describe('validators', () => {
    const validMessage = { valid: true }
    const mockCheckState = (_) => validMessage
    const mockCheckTransferParameters = (_) => validMessage
    const mockCheckMolarityResult = (_) => validMessage
    const mockCheckId = (_) => validMessage

    beforeEach(() => {
      checkState.mockClear()
      checkTransferParameters.mockClear()
      checkMolarityResult.mockClear()
      checkId.mockClear()

      checkState.mockReturnValue(mockCheckState)
      checkTransferParameters.mockReturnValue(mockCheckTransferParameters)
      checkMolarityResult.mockReturnValue(mockCheckMolarityResult)
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
      expect(checkTransferParameters.mock.calls[0][0]).toEqual({
        testKey: 'testValue',
      })
    })

    it('passed the correct parameters to checkId', () => {
      const wrapper = wrapperFactory()

      // Before setting a source tube
      expect(checkId.mock.calls[0][0]).toEqual([])
      expect(checkId.mock.calls[0][1]).toEqual('Does not match the source tube')

      wrapper.vm.updateSourceTube({
        labware: {
          receptacle: { downstream_tubes: [{ id: 'test1' }, { id: 'test2' }] },
        },
      })
      wrapper.vm.destinationTubeValidators // Refresh the evaluation to cause more calls to checkId

      // After setting a source tube
      expect(checkId.mock.calls[1][0]).toEqual(['test1', 'test2'])
      expect(checkId.mock.calls[1][1]).toEqual('Does not match the source tube')
    })
  })

  describe('allValid', () => {
    test.each([
      ['empty', 'empty', false],
      ['invalid', 'invalid', false],
      ['valid', 'empty', false],
      ['valid', 'invalid', false],
      ['empty', 'valid', false],
      ['invalid', 'valid', false],
      ['valid', 'valid', true],
    ])('with %p source tube and %p destination tube, returns %p', (sourceState, destinationState, result) => {
      const wrapper = wrapperFactory()
      wrapper.vm.sourceTube = { state: sourceState }
      wrapper.vm.destinationTube = { state: destinationState }
      expect(wrapper.vm.allValid).toBe(result)
    })
  })

  describe('updateSourceTube', () => {
    it('updates the source tube', () => {
      const wrapper = wrapperFactory()
      const tube = { testKey: 'testValue' }
      wrapper.vm.updateSourceTube(tube)
      expect(wrapper.vm.sourceTube).toEqual({
        labware: null,
        state: 'empty',
        testKey: 'testValue',
      })
    })
  })

  describe('updateDestinationTube', () => {
    it('updates the destination tube', () => {
      const wrapper = wrapperFactory()
      const tube = { testKey: 'testValue' }
      wrapper.vm.updateDestinationTube(tube)
      expect(wrapper.vm.destinationTube).toEqual({
        labware: null,
        state: 'empty',
        testKey: 'testValue',
      })
    })
  })
})
