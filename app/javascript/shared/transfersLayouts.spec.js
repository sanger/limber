import { transfersFromRequests } from './transfersLayouts'
import { requestsFromPlates } from './requestHelpers'
import { plateFactory, wellFactory, requestFactory } from 'test_support/factories'


describe('transfersLayouts', () => {
  const requests1 = [
    requestFactory({uuid: 'req-1-uuid'}),
    requestFactory({uuid: 'req-2-uuid'})
  ]
  const requests2 = [
    requestFactory({uuid: 'req-3-uuid'}),
    requestFactory({uuid: 'req-4-uuid'})
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

