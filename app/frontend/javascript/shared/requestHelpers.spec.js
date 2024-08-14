import { handleFailedRequest } from '@/javascript/shared/requestHelpers.js'
import eventBus from '@/javascript/shared/eventBus.js'

describe('handleFailedRequest', () => {
  it('emits a danger alert with the provided payload', () => {
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
      message: 'message1, message2',
    })

    mockEmit.mockRestore()
  })
})
