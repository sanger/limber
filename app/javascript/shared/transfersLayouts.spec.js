import { transfersFromRequests, buildPlatesMatrix, buildLibrarySplitPlatesMatrix, buildSequentialLibrarySplitTransfersArray } from './transfersLayouts'
import { requestsFromPlates } from './requestHelpers'
import { plateFactory, wellFactory, requestFactory } from 'test_support/factories'


describe('transfersLayouts.js', () => {
  const requests1 = [
    requestFactory({uuid: 'req-1-uuid', library_type: 'A'}),
    requestFactory({uuid: 'req-2-uuid', library_type: 'B'})
  ]
  const requests2 = [
    requestFactory({uuid: 'req-3-uuid', library_type: 'A'}),
    requestFactory({uuid: 'req-4-uuid', library_type: 'B'})
  ]
  const well1 = wellFactory({
    uuid: 'well-1-uuid',
    requests_as_source: requests1,
    position: { name: 'A1' }
  })
  const well2 = wellFactory({
    uuid: 'well-2-uuid',
    requests_as_source: requests2,
    position: { name: 'B2' }
  })
  const plateObj1 = { plate: plateFactory({ uuid: 'plate-1-uuid', id: '1', wells: [well1] }), index: 0 }
  const plateObj2 = { plate: plateFactory({ uuid: 'plate-2-uuid', id: '2', wells: [well2] }), index: 1 }
  const requests = requestsFromPlates([plateObj1, plateObj2])


  describe('#buildPlatesMatrix', () => {
    it('returns same number of plates as source it received as argument', () => {
      const result = buildPlatesMatrix(requests, 2, 96)

      expect(result.platesMatrix.length).toEqual(2)
    })
    it('returns empty for the list of duplicates', () => {
      const result = buildPlatesMatrix(requests, 2, 96)

      expect(result.duplicatedRequests.length).toEqual(2)
    })
  })
  
  describe('#buildLibrarySplitPlatesMatrix', () => {
    it('returns as many plates as library types defined', () => {
      const result = buildLibrarySplitPlatesMatrix(requests)

      expect(result.platesMatrix.length).toEqual(2)
    })
    it('returns the right set of requests for each library type', () => {
      const result = buildLibrarySplitPlatesMatrix(requests)

      expect(result.platesMatrix[0]).toEqual({
        'A': [requests[0]],
        'B': [requests[1]]
      })
      expect(result.platesMatrix[1]).toEqual({
        'A': [undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, requests[2]],
        'B': [undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, requests[3]]
      })
    })
    it('returns empty for the list of duplicates', () => {
      const result = buildLibrarySplitPlatesMatrix(requests)

      expect(result.duplicatedRequests.length).toEqual(0)
    })

    describe('when there is clash with library types', () => {
      const requests1 = [
        requestFactory({uuid: 'req-1-uuid', library_type: 'A'}),
        requestFactory({uuid: 'req-2-uuid', library_type: 'A'})
      ]
      const requests2 = [
        requestFactory({uuid: 'req-3-uuid', library_type: 'B'}),
        requestFactory({uuid: 'req-4-uuid', library_type: 'B'})
      ]
      const well1 = wellFactory({
        uuid: 'well-1-uuid',
        requests_as_source: requests1,
        position: { name: 'A1' }
      })
      const well2 = wellFactory({
        uuid: 'well-2-uuid',
        requests_as_source: requests2,
        position: { name: 'B2' }
      })
      const plateObj1 = { plate: plateFactory({ uuid: 'plate-1-uuid', id: '1', wells: [well1] }), index: 0 }
      const plateObj2 = { plate: plateFactory({ uuid: 'plate-2-uuid', id: '2', wells: [well2] }), index: 1 }
      const requests = requestsFromPlates([plateObj1, plateObj2])

      it('returns as many plates as library types defined', () => {
        const result = buildLibrarySplitPlatesMatrix(requests)
  
        expect(result.platesMatrix.length).toEqual(2)
      })
      it('returns the right requests for each library type', () => {
        const result = buildLibrarySplitPlatesMatrix(requests)

        // I only get requests[0] because requests[1] is a clash on library
        expect(result.platesMatrix[0]).toEqual({
          'A': [requests[0]]
        })
        // I only get requests[2] because requests[3] is a clash on library
        expect(result.platesMatrix[1]).toEqual({
          'B': [undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, undefined, requests[2]]
        })

      })
      it('returns the list of duplicates', () => {
        const result = buildLibrarySplitPlatesMatrix(requests, 2, 96)
  
        expect(result.duplicatedRequests.length).toEqual(2)
        expect(result.duplicatedRequests).toEqual([requests[1],requests[3]])
      })        
    })
  })
  
  describe('#buildSequentialLibrarySplitTransfersArray', () => {
    const requests1 = [
      requestFactory({uuid: 'req-1-uuid', library_type: 'A'}),
      requestFactory({uuid: 'req-2-uuid', library_type: 'A'})
    ]
    const requests2 = [
      requestFactory({uuid: 'req-3-uuid', library_type: 'B'}),
      requestFactory({uuid: 'req-4-uuid', library_type: 'B'})
    ]
    const well1 = wellFactory({
      uuid: 'well-1-uuid',
      requests_as_source: requests1,
      position: { name: 'A2' }
    })
    const well2 = wellFactory({
      uuid: 'well-2-uuid',
      requests_as_source: requests2,
      position: { name: 'B2' }
    })
    const plateObj1 = { plate: plateFactory({ uuid: 'plate-1-uuid', id: '1', wells: [well1] }), index: 0 }
    const plateObj2 = { plate: plateFactory({ uuid: 'plate-2-uuid', id: '2', wells: [well2] }), index: 1 }

    const transfers = [
      {
        request: requests1, 
        well: well1, 
        plateObj: plateObj1
      },
      {
        request: requests2, 
        well: well2, 
        plateObj: plateObj2
      }
    ]
    it('checks that wells are generated in same order that were in the input', () =>{
      let result = buildSequentialLibrarySplitTransfersArray(transfers)
      expect(result[0].targetWell).toEqual('A2')
      expect(result[1].targetWell).toEqual('B5')
    })
  })

  describe('#transferFromRequests', () => {
    it('throws an error if invalid layout is provided', () => {
      expect(() => transfersFromRequests(requests, 'invalid')).toThrow('Invalid transfers layout name: invalid')
    })
  
    it('creates the correct transfersFromRequests with sequential layout', () => {
      const transfersResults = transfersFromRequests(requests, 'sequential')
  
      expect(transfersResults.valid).toEqual([
        {
          request: requests1[0],
          well: well1,
          plateObj: plateObj1,
          targetWell: 'A1'
        },
        {
          request: requests2[0],
          well: well2,
          plateObj: plateObj2,
          targetWell: 'B1'
        }
      ])
  
      expect(transfersResults.duplicated).toEqual([
        {
          request: requests1[1],
          well: well1,
          plateObj: plateObj1,
          targetWell: 'A1'
        },
        {
          request: requests2[1],
          well: well2,
          plateObj: plateObj2,
          targetWell: 'B1'
        }
      ])
    })
  
  
    it('creates the correct transfersFromRequests with quadrant layout', () => {
      const transfersResults = transfersFromRequests(requests, 'quadrant')
  
      expect(transfersResults.valid).toEqual([
        {
          request: requests1[0],
          well: well1,
          plateObj: plateObj1,
          targetWell: 'A1'
        },
        {
          request: requests2[0],
          well: well2,
          plateObj: plateObj2,
          targetWell: 'D3'
        }
      ])
  
      expect(transfersResults.duplicated).toEqual([
        {
          request: requests1[1],
          well: well1,
          plateObj: plateObj1,
          targetWell: 'A1'
        },
        {
          request: requests2[1],
          well: well2,
          plateObj: plateObj2,
          targetWell: 'D3'
        }
      ])
    })  
  })
})

