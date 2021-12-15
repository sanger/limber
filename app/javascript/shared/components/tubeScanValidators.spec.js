import {
  checkDuplicates,
  checkId,
  checkMatchingPurposes,
  checkMolarityResult,
  checkState,
  checkTransferParameters
} from 'shared/components/tubeScanValidators'

import { purposeConfigForTube } from 'shared/tubeHelpers'
import {
  purposeTargetMolarityParameter,
  purposeTargetVolumeParameter,
  purposeMinimumPickParameter,
  tubeMostRecentMolarity,
} from 'shared/tubeTransferVolumes'

jest.mock('shared/tubeHelpers')
jest.mock('shared/tubeTransferVolumes')

describe('checkDuplicates', () => {
  it('passes if it has distinct tubes', () => {
    const tube1 = { uuid: 'tube-uuid-1' }
    const tube2 = { uuid: 'tube-uuid-2' }

    expect(
      checkDuplicates([tube1, tube2])(tube1)
    ).toEqual({ valid: true })
  })

  it('fails if there are duplicate tubes', () => {
    const tube1 = { uuid: 'tube-uuid-1' }

    expect(
      checkDuplicates([tube1, tube1])(tube1)
    ).toEqual({ valid: false, message: 'Barcode has been scanned multiple times' })
  })

  xit('fails if there are duplicate tubes even when the parent has not been updated', () => {
    // We emit the tube and state as a single event, and want to avoid the situation
    // where tubes flick from valid to invalid
    const empty  = null
    const tube1 = { uuid: 'tube-uuid-1' }

    expect(
      checkDuplicates([empty, tube1])(tube1)
    ).toEqual({ valid: false, message: 'Barcode has been scanned multiple times' })
  })

  it('passes if it has distinct tubes and the parent has not been updated', () => {
    const empty  = null
    const tube1 = { uuid: 'tube-uuid-1' }
    const tube2 = { uuid: 'tube-uuid-2' }

    expect(
      checkDuplicates([empty, tube2])(tube1)
    ).toEqual({ valid: true })
  })
})

describe('checkId', () => {
  const validIds = ['123', '456', '789']

  test.each(validIds)('passes a tube with acceptable ID %p as valid', testId => {
    const tube = { id: testId }
    expect(checkId(validIds)(tube)).toEqual({ valid: true })
  })

  const errorMessage = 'Test error'

  describe('undefined tube', () => {
    it('is marked as invalid', () => {
      expect(checkId(validIds)(undefined)).toEqual({ valid: false })
    })

    it('is given the specified error message', () => {
      expect(checkId(validIds, errorMessage)(undefined)).toEqual({ valid: false, message: errorMessage })
    })
  })

  describe('tube with no ID', () => {
    const tube = { }

    it('is marked as invalid', () => {
      expect(checkId(validIds)(tube)).toEqual({ valid: false })
    })

    it('is given the specified error message', () => {
      expect(checkId(validIds, errorMessage)(tube)).toEqual({ valid: false, message: errorMessage })
    })
  })

  describe('tube with invalid ID', () => {
    const tube = { id: '999' }

    it('is marked as invalid', () => {
      expect(checkId(validIds)(tube)).toEqual({ valid: false })
    })

    it('is given the specified error message', () => {
      expect(checkId(validIds, errorMessage)(tube)).toEqual({ valid: false, message: errorMessage })
    })
  })
})

describe('checkMatchingPurposes', () => {
  it('passes if the tube has a matching purpose', () => {
    const tube = { purpose: { name: 'A Purpose' } }
    expect(checkMatchingPurposes({ name: 'A Purpose' })(tube)).toEqual({ valid: true })
  })

  it('passes if the tube is undefined', () => {
    const tube = undefined
    expect(checkMatchingPurposes({ name: 'A Purpose' })(tube)).toEqual({ valid: true })
  })

  it('passes if the reference purpose is undefined', () => {
    const tube = { purpose: { name: 'A Purpose' } }
    expect(checkMatchingPurposes(undefined)(tube)).toEqual({ valid: true })
  })

  it('fails if the tube purpose is undefined', () => {
    const tube = {}
    expect(checkMatchingPurposes({ name: 'A Purpose' })(tube))
      .toEqual({ valid: false, message: 'Tube purpose \'UNKNOWN\' doesn\'t match other tubes' })
  })

  it('fails if the tube purpose doesn\'t match the reference purpose', () => {
    const tube = { purpose: { name: 'Another Purpose' } }
    expect(checkMatchingPurposes({ name: 'A Purpose' })(tube))
      .toEqual({ valid: false, message: 'Tube purpose \'Another Purpose\' doesn\'t match other tubes' })
  })
})

describe('checkMolarityResult', () => {
  const tube = {}

  describe('when the tube has molarity results', () => {
    beforeEach(() => {
      tubeMostRecentMolarity.mockReturnValue(2.0)
    })

    it('passes the tube', () => {
      expect(checkMolarityResult()(tube)).toEqual({ valid: true })
    })

    it('passes an undefined tube', () => {
      expect(checkMolarityResult()(undefined)).toEqual({ valid: true })
    })
  })

  describe('when the tube has no molarity results', () => {
    const failureMessage = 'Tube has no molarity QC result'

    beforeEach(() => {
      tubeMostRecentMolarity.mockReturnValue(undefined)
    })

    it('fails the tube', () => {
      expect(checkMolarityResult()(tube)).toEqual({ valid: false, message: failureMessage })
    })

    it('fails an undefined tube', () => {
      expect(checkMolarityResult()(undefined)).toEqual({ valid: false, message: failureMessage })
    })
  })
})

describe('checkState', () => {
  it('passes if the state is in the allowed list', () => {
    const tube = { state: 'available' }

    expect(
      checkState(['available', 'exhausted'],0)(tube)
    ).toEqual({ valid: true })
  })

  it('fails if the state is not in the allowed list', () => {
    const tube = { state: 'destroyed' }

    expect(
      checkState(['available', 'exhausted'],0)(tube)
    ).toEqual({ valid: false, message: 'Tube must have a state of: available or exhausted' })
  })
})

describe('checkTransferParameters', () => {
  const purposeConfigs = { } // Just an Object we can validate as passed to other methods
  const purposeConfig = { } // Another dummy Object we can validate against

  beforeEach(() => {
    purposeConfigForTube.mockReturnValue(purposeConfig)
  })

  const tube = { }
  const invalidMessage = 'Tube purpose is not configured for generating transfer volumes'

  describe('all transfer parameters', () => {
    beforeEach(() => {
      purposeTargetMolarityParameter.mockReturnValue(4)
      purposeTargetVolumeParameter.mockReturnValue(192)
      purposeMinimumPickParameter.mockReturnValue(2)
    })

    it('passes tube and purposeConfigs to the purposeConfigForTube method', () => {
      checkTransferParameters(purposeConfigs)(tube)

      expect(purposeConfigForTube.mock.calls.length).toBe(1)
      expect(purposeConfigForTube.mock.calls[0][0]).toBe(tube)
      expect(purposeConfigForTube.mock.calls[0][1]).toBe(purposeConfigs)
    })

    it('passes purposeConfig to all transfer parameter methods', () => {
      checkTransferParameters(purposeConfigs)(tube)

      expect(purposeTargetMolarityParameter.mock.calls.length).toBe(1)
      expect(purposeTargetMolarityParameter.mock.calls[0][0]).toBe(purposeConfig)

      expect(purposeTargetVolumeParameter.mock.calls.length).toBe(1)
      expect(purposeTargetVolumeParameter.mock.calls[0][0]).toBe(purposeConfig)

      expect(purposeMinimumPickParameter.mock.calls.length).toBe(1)
      expect(purposeMinimumPickParameter.mock.calls[0][0]).toBe(purposeConfig)
    })

    it('passes the tube', () => {
      expect(checkTransferParameters(purposeConfigs)(tube)).toEqual({ valid: true })
    })
  })

  describe('missing target molarity transfer parameter', () => {
    beforeEach(() => {
      purposeTargetMolarityParameter.mockReturnValue(undefined)
      purposeTargetVolumeParameter.mockReturnValue(192)
      purposeMinimumPickParameter.mockReturnValue(2)
    })

    it('fails the tube', () => {
      expect(checkTransferParameters(purposeConfigs)(tube)).toEqual({ valid: false, message: invalidMessage })
    })
  })

  describe('missing target volume transfer parameter', () => {
    beforeEach(() => {
      purposeTargetMolarityParameter.mockReturnValue(4)
      purposeTargetVolumeParameter.mockReturnValue(undefined)
      purposeMinimumPickParameter.mockReturnValue(2)
    })

    it('fails the tube', () => {
      expect(checkTransferParameters(purposeConfigs)(tube)).toEqual({ valid: false, message: invalidMessage })
    })
  })

  describe('missing minimum pick transfer parameter', () => {
    beforeEach(() => {
      purposeTargetMolarityParameter.mockReturnValue(4)
      purposeTargetVolumeParameter.mockReturnValue(192)
      purposeMinimumPickParameter.mockReturnValue(undefined)
    })

    it('fails the tube', () => {
      expect(checkTransferParameters(purposeConfigs)(tube)).toEqual({ valid: false, message: invalidMessage })
    })
  })
})
