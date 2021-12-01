import {
  purposeTargetMolarityParameter,
  purposeTargetVolumeParameter,
  purposeMinimumPickParameter,
  calculateTransferVolumes
} from 'shared/tubeTransferVolumes'

const validPurposeConfig = {
  transfer_parameters: {
    target_molarity_nm: 4,
    target_volume_ul: 192,
    minimum_pick_ul: 2
  }
}

const emptyPurposeConfig = { }

describe('purposeTargetMolarityParameter', () => {
  describe('with complete transfer purposeConfig', () => {
    it('returns the correct value', () => {
      expect(purposeTargetMolarityParameter(validPurposeConfig)).toBe(4)
    })
  })

  describe('with no transfer parameters', () => {
    it('returns undefined', () => {
      expect(purposeTargetMolarityParameter(emptyPurposeConfig)).toBeUndefined()
    })
  })

  describe('with undefined purposeConfig', () => {
    it('returns undefined', () => {
      expect(purposeTargetMolarityParameter(undefined)).toBeUndefined()
    })
  })
})

describe('purposeTargetVolumeParameter', () => {
  describe('with complete transfer purposeConfig', () => {
    it('returns the correct value', () => {
      expect(purposeTargetVolumeParameter(validPurposeConfig)).toBe(192)
    })
  })

  describe('with no transfer parameters', () => {
    it('returns undefined', () => {
      expect(purposeTargetVolumeParameter(emptyPurposeConfig)).toBeUndefined()
    })
  })

  describe('with undefined purposeConfig', () => {
    it('returns undefined', () => {
      expect(purposeTargetVolumeParameter(undefined)).toBeUndefined()
    })
  })
})

describe('purposeMinimumPickParameter', () => {
  describe('with complete transfer purposeConfig', () => {
    it('returns the correct value', () => {
      expect(purposeMinimumPickParameter(validPurposeConfig)).toBe(2)
    })
  })

  describe('with no transfer parameters', () => {
    it('returns undefined', () => {
      expect(purposeMinimumPickParameter(emptyPurposeConfig)).toBeUndefined()
    })
  })

  describe('with undefined purposeConfig', () => {
    it('returns undefined', () => {
      expect(purposeMinimumPickParameter(undefined)).toBeUndefined()
    })
  })
})

describe('tubeMostRecentMolarity', () => {

})

describe('calculateTransferVolumes', () => {
  describe('valid and complete inputs', () => {
    const volumes = calculateTransferVolumes(5, 200, 15, 2)

    it('returns an object', () => {
      expect(volumes).toBeInstanceOf(Object)
    })

    it('returns an object with the correct keys', () => {
      expect(Object.keys(volumes)).toEqual(['sampleVolume', 'bufferVolume'])
    })

    test.each(Object.keys(volumes))
    (
      'returns an object with value for key %p as a Number',
      (key) => {
        expect(volumes[key]).toEqual(expect.any(Number))
      }
    )

    it('returns the correctly calculated values', () => {
      expect(volumes.sampleVolume).toBeCloseTo(66.667, 3)
      expect(volumes.bufferVolume).toBeCloseTo(133.333, 3)
    })
  })

  describe('low concentration sample', () => {
    const volumes = calculateTransferVolumes(5, 200, 3, 2)

    it('returns the correctly calculated values', () => {
      expect(volumes.sampleVolume).toBe(200)
      expect(volumes.bufferVolume).toBe(0)
    })
  })

  describe('low buffer pick volume', () => {
    const volumes = calculateTransferVolumes(5, 200, 5.02, 2)

    it('returns the correctly calculated values', () => {
      expect(volumes.sampleVolume).toBe(200)
      expect(volumes.bufferVolume).toBe(0)
    })
  })

  describe('low sample pick volume', () => {
    const volumes = calculateTransferVolumes(5, 200, 750, 2)

    it('returns the correctly calculated values', () => {
      expect(volumes.sampleVolume).toBe(2)
      expect(volumes.bufferVolume).toBe(198)
    })
  })
})
