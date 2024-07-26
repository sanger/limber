import { findUniqueIndex, requestsForWell } from './wellHelpers'

describe('wellHelpers', () => {
  describe('findUniqueIndex', () => {
    it('returns -1 when the element is not in the list', () => {
      expect(findUniqueIndex([5, 1, 2, 1, 2, 3], 0)).toBe(-1)
      expect(findUniqueIndex([5, 1, 2, 1, 2, 3], 4)).toBe(-1)
      expect(findUniqueIndex([5, 1, 2, 1, 2, 3], 6)).toBe(-1)
    })

    it('returns the index of the element in the unique list', () => {
      expect(findUniqueIndex([5, 1, 2, 1, 2, 3], 1)).toBe(1)
      expect(findUniqueIndex([5, 1, 2, 1, 2, 3], 2)).toBe(2)
      expect(findUniqueIndex([5, 1, 2, 1, 2, 3], 3)).toBe(3)
      expect(findUniqueIndex([5, 1, 2, 1, 2, 3], 5)).toBe(0)
    })
  })

  describe('requestsForWell', () => {
    const request1 = { uuid: 'req-1' }
    const request2 = { uuid: 'req-2' }

    // This function is used in MultiStamp, which is used in two scenarios:
    // 1: where the well is on a plate that had a submission on it, so has requests_as_source
    // 2: where the well is on a plate downstream of the submission plate, so has requests on its aliquots
    // So this function pulls both types of request out.
    it('combines requests from both data sources', () => {
      const well = {
        uuid: 'well-1',
        position: { name: 'A1' },
        aliquots: [
          {
            uuid: 'ali-1',
            request: request1,
          }
        ],
        requests_as_source: [request2],
      }

      expect(requestsForWell(well).sort()).toEqual([request2, request1])
    })

    // Different aliquots in the same well can reference the same request:
    // this happens on the LRC GEM-X 5p Aggregate plate in the scRNA Core pipeline.
    // The same request could theoretically be present in both requests_as_source and aliquots,
    // or twice in requests_as_source,
    // although I don't know of a realistic scenario where this would happen.
    it('de-duplicates across both data sources', () => {
      const well = {
        uuid: 'well-1',
        position: { name: 'A1' },
        aliquots: [
          {
            uuid: 'ali-1',
            request: request1,
          },
          {
            uuid: 'ali-2',
            request: request1,
          }
        ],
        requests_as_source: [request1, request1],
      }

      expect(requestsForWell(well)).toEqual([request1])
    })

    // If an aliquot has no request, it is not included in the output.
    it('removes falsy values', () => {
      const well = {
        uuid: 'well-1',
        position: { name: 'A1' },
        aliquots: [
          {
            uuid: 'ali-1',
            request: null,
          }
        ],
        requests_as_source: [request1],
      }

      expect(requestsForWell(well)).toEqual([request1])
    })
  })
})
