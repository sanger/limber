import { handleFailedRequest } from '@/javascript/shared/requestHelpers.js'
import eventBus from '@/javascript/shared/eventBus.js'

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
