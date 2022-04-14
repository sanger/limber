import { buildTubeObjs, purposeConfigForTube } from 'shared/tubeHelpers'

describe('tubeHelpers', () => {
  describe('buildTubeObjs', () => {
    it('generates an array of empty tubes', () => {
      const emptyTube = { state: 'empty', labware: null }

      expect(buildTubeObjs(3)).toEqual([
        { ...emptyTube, index: 0 },
        { ...emptyTube, index: 1 },
        { ...emptyTube, index: 2 },
      ])
    })
  })

  describe('purposeConfigForTube', () => {
    const purposeConfigs = {
      purposeA: { uuid: 'purposeA', id: 'purposeAId' },
      purposeB: { uuid: 'purposeB', id: 'purposeBId' },
    }

    test.each([
      ['purposeA', 'purposeAId'],
      ['purposeB', 'purposeBId'],
    ])('tube with purpose UUID %p returns purpose with identifier %p', (uuid, identifier) => {
      const tube = { purpose: { uuid: uuid } }
      const purpose = purposeConfigForTube(tube, purposeConfigs)

      expect(purpose).not.toBeNull()
      expect(purpose.id).toBe(identifier)
    })

    describe('unrecognised tube', () => {
      const tube = { purpose: { uuid: 'purposeC' } }

      it('returns an undefined purpose', () => {
        expect(purposeConfigForTube(tube, purposeConfigs)).toBeUndefined()
      })
    })

    describe('undefined purposeConfigs', () => {
      const tube = { purpose: { uuid: 'purposeA' } }

      it('returns an undefined purpose', () => {
        expect(purposeConfigForTube(tube, undefined)).toBeUndefined()
      })
    })

    describe('tube with no purpose', () => {
      const tube = {}

      it('returns an undefined purpose', () => {
        expect(purposeConfigForTube(tube, purposeConfigs)).toBeUndefined()
      })
    })

    describe('tube with a purpose but no UUID', () => {
      const tube = { purpose: {} }

      it('returns an undefined purpose', () => {
        expect(purposeConfigForTube(tube, purposeConfigs)).toBeUndefined()
      })
    })

    describe('undefined tube', () => {
      it('returns an undefined purpose', () => {
        expect(purposeConfigForTube(undefined, purposeConfigs)).toBeUndefined()
      })
    })
  })
})
