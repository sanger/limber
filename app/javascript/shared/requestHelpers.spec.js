import { handleFailedRequest } from '@/shared/requestHelpers'
import eventBus from '@/shared/eventBus'

describe('handleFailedRequest', () => {
  it('emits a danger alert with the provided payload', () => {
    const mockEmit = jest.spyOn(eventBus, '$emit')
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
