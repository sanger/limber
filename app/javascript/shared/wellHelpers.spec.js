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
    const request1 = { uuid: '1' }
    const request2 = { uuid: '2' }

    const well = {
      uuid: '3',
      position: { name: 'A1' },
      aliquots: [
        {
          uuid: '4',
          request: request1,
        },
        {
          uuid: '5',
          request: null,
        },
      ],
      requests_as_source: [request1, request2],
    }

    it('combines requests from both data sources and de-duplicates', () => {
      expect(requestsForWell(well)).toEqual([request1, request2])
    })
  })
})
