import { allWellsFromPlates, handleFailedRequest } from '@/javascript/shared/requestHelpers.js'
import eventBus from '@/javascript/shared/eventBus.js'

describe('allWellsFromPlates', () => {
  const buildPlateObj = (index, wells) => ({
    index,
    state: 'valid',
    plate: { uuid: `plate-uuid-${index}`, wells },
  })

  const buildWell = (position, aliquotCount = 0) => ({
    uuid: `well-uuid-${position}`,
    position: { name: position },
    aliquots: Array.from({ length: aliquotCount }, (_, i) => ({ uuid: `aliquot-${position}-${i}` })),
  })

  it('returns an empty array when given no plates', () => {
    expect(allWellsFromPlates([])).toEqual([])
  })

  it('returns an empty array when all wells are empty', () => {
    const plateObj = buildPlateObj(0, [buildWell('A1'), buildWell('B1')])
    expect(allWellsFromPlates([plateObj])).toEqual([])
  })

  it('returns only wells that have aliquots', () => {
    const emptyWell = buildWell('A1', 0)
    const occupiedWell = buildWell('B1', 1)
    const plateObj = buildPlateObj(0, [emptyWell, occupiedWell])

    const result = allWellsFromPlates([plateObj])

    expect(result).toHaveLength(1)
    expect(result[0].well).toBe(occupiedWell)
  })

  it('sets request to undefined for each returned entry', () => {
    const plateObj = buildPlateObj(0, [buildWell('A1', 2)])

    const result = allWellsFromPlates([plateObj])

    expect(result[0].request).toBeUndefined()
  })

  it('includes the correct plateObj reference on each entry', () => {
    const plateObj = buildPlateObj(0, [buildWell('A1', 1)])

    const result = allWellsFromPlates([plateObj])

    expect(result[0].plateObj).toBe(plateObj)
  })

  it('returns entries for all occupied wells across multiple plates', () => {
    const plate0 = buildPlateObj(0, [buildWell('A1', 1), buildWell('B1', 0)])
    const plate1 = buildPlateObj(1, [buildWell('A1', 0), buildWell('C1', 3)])

    const result = allWellsFromPlates([plate0, plate1])

    expect(result).toHaveLength(2)
    expect(result[0].well.position.name).toBe('A1')
    expect(result[0].plateObj).toBe(plate0)
    expect(result[1].well.position.name).toBe('C1')
    expect(result[1].plateObj).toBe(plate1)
  })
})

describe('handleFailedRequest', () => {
  it('emits a danger alert with a formatted message when response contains an array', () => {
    const mockEmit = vi.spyOn(eventBus, '$emit')
    const mockRequestPayload = {
      response: {
        data: {
          message: [['message1', 'message2'], 'title'],
        },
      },
    }

    handleFailedRequest(mockRequestPayload)

    expect(mockEmit).toHaveBeenCalledWith('push-alert', {
      level: 'danger',
      title: 'title',
      message: 'message1, message2', // Matches the formatted message
    })

    mockEmit.mockRestore()
  })

  it('emits a danger alert with a fallback message when response contains a single message', () => {
    const mockEmit = vi.spyOn(eventBus, '$emit')
    const mockRequestPayload = {
      response: {
        data: {
          message: 'Single error message',
        },
        statusText: 'Bad Request',
      },
    }

    handleFailedRequest(mockRequestPayload)

    expect(mockEmit).toHaveBeenCalledWith('push-alert', {
      level: 'danger',
      title: 'Bad Request', // Fallback title from statusText
      message: 'Single error message', // Single message is used directly
    })

    mockEmit.mockRestore()
  })

  it('emits a danger alert with default values when response is missing', () => {
    const mockEmit = vi.spyOn(eventBus, '$emit')
    const mockRequestPayload = {}

    handleFailedRequest(mockRequestPayload)

    expect(mockEmit).toHaveBeenCalledWith('push-alert', {
      level: 'danger',
      title: 'Unexpected error', // Default title
      message: 'Cannot determine error messages', // Default message
    })

    mockEmit.mockRestore()
  })

  it('emits a danger alert with a fallback message when response has no array but has a message', () => {
    const mockEmit = vi.spyOn(eventBus, '$emit')
    const mockRequestPayload = {
      response: {
        data: {
          message: 'Error occurred',
        },
        statusText: 'Internal Server Error',
      },
    }

    handleFailedRequest(mockRequestPayload)

    expect(mockEmit).toHaveBeenCalledWith('push-alert', {
      level: 'danger',
      title: 'Internal Server Error', // Fallback title from statusText
      message: 'Error occurred', // Message from response data
    })

    mockEmit.mockRestore()
  })

  it('emits a danger alert with a fallback message when response has no message', () => {
    const mockEmit = vi.spyOn(eventBus, '$emit')
    const mockRequestPayload = {
      response: {
        statusText: 'Service Unavailable',
      },
    }

    handleFailedRequest(mockRequestPayload)

    expect(mockEmit).toHaveBeenCalledWith('push-alert', {
      level: 'danger',
      title: 'Service Unavailable', // Fallback title from statusText
      message: 'Cannot parse messages', // Fallback message
    })

    mockEmit.mockRestore()
  })
})
