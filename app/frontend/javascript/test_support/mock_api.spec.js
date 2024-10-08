import mockApi from './mock_api.js'

describe('mockApi', () => {
  let api = mockApi()

  const barcode = 'DN12345'
  const mockTube = { type: 'tube', id: 123 }

  it('should make a get request and return a single tube', async () => {
    api.mockGet(`labware/${barcode}`, {}, { data: mockTube })

    let response = await api.devour.one('labware', barcode).get()

    expect(response.data).toEqual(mockTube)
    expect(response.errors).toEqual(undefined)
    expect(response.meta).toEqual(undefined)
    expect(response.links).toEqual(undefined)
  })

  it('should make a findall request and return an array of tubes', async () => {
    api.mockGet('labware', { filter: { barcode: barcode } }, { data: [mockTube] })

    let response = await api.devour.findAll('labware', {
      filter: { barcode: barcode },
    })

    expect(response.data).toEqual([mockTube])
    expect(response.errors).toEqual(undefined)
    expect(response.meta).toEqual(undefined)
    expect(response.links).toEqual(undefined)
  })

  it('should make a failed request and return an error', async () => {
    api.mockFail(
      'server-errors/500',
      {},
      {
        errors: [
          {
            detail: 'A server error occurred',
            code: 500,
            status: 500,
          },
        ],
      },
    )

    let response = await api.devour
      .one('server-errors', '500')
      .get()
      .catch((err) => {
        return err
      })

    expect(response).toEqual({ 0: { detail: 'A server error occurred', code: 500, status: 500 } })
  })
})
