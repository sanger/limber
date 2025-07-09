// // Import the component being tested
import commentStoreFactory from './comment-store.js'
import { flushPromises } from '@vue/test-utils'
import mockApi from '@/javascript/test_support/mock_api.js'
import { jsonCollectionFactory } from '@/javascript/test_support/factories.js'
import eventBus from '@/javascript/shared/eventBus.js'

describe('commentStore', () => {
  let mockEmit
  beforeEach(() => {
    mockEmit = vi.spyOn(eventBus, '$emit')
  })
  const noComments = { data: [] }
  const comments = jsonCollectionFactory('comment', [
    {
      title: 'This is a title',
      description: 'This is a comment',
      created_at: '2017-08-31T11:18:16+01:00',
      updated_at: '2017-08-31T11:18:16+01:00',
      user: {
        login: 'js1',
        first_name: 'John',
        last_name: 'Smith',
      },
    },
    {
      title: 'This is also a title',
      description: 'This is also a comment',
      created_at: '2017-09-30T11:18:16+01:00',
      updated_at: '2017-09-30T11:18:16+01:00',
      user: {
        login: 'js2',
        first_name: 'Jane',
        last_name: 'Smythe',
      },
    },
  ])

  const mockApiFactory = function (response) {
    let api = mockApi()
    api.mockGet('labware/123/comments', { include: 'user' }, response)
    return api.devour
  }

  it('retrieves comments for an uncommented labware when prompted', async () => {
    let api = mockApiFactory(noComments)
    let commentStore = commentStoreFactory(null, api, '123', 'user_id')

    commentStore.refreshComments()

    await flushPromises()

    expect(commentStore.comments).toEqual([])
  })

  it('retrieves comments for a commented labware when prompted', async () => {
    let api = mockApiFactory(comments)
    let commentStore = commentStoreFactory(null, api, '123', 'user_id')

    commentStore.refreshComments()

    await flushPromises()

    expect(commentStore.comments.length).toEqual(2)
  })

  it('retrieves comments after adding a new comment', async () => {
    let api = mockApiFactory(comments)
    let mock = vi.fn().mockResolvedValue({ data: {} })
    let commentStore = commentStoreFactory(mock, api, '123', 'user_id')

    expect(commentStore.comments).toEqual(undefined)

    commentStore.addComment('new title', 'new description')

    await flushPromises()

    expect(mock).toHaveBeenCalledTimes(1)
    expect(commentStore.comments.length).toEqual(2)
    expect(mockEmit).toHaveBeenCalledWith('update-comments', { comments: commentStore.comments, assetId: '123' })
  })

  it('posts comments to the sequencescape api', async () => {
    let api = mockApiFactory(comments)
    let mock = vi.fn().mockResolvedValue({ data: {} })
    let commentStore = commentStoreFactory(mock, api, '123', 'user_id')

    const expectedPayload = {
      data: {
        type: 'comments',
        attributes: {
          title: 'new title',
          description: 'new description',
        },
        relationships: {
          commentable: {
            data: { type: 'labware', id: '123' },
          },
          user: {
            data: { type: 'users', id: 'user_id' },
          },
        },
      },
    }

    commentStore.addComment('new title', 'new description')

    await flushPromises()

    expect(mock).toHaveBeenCalledTimes(1)
    expect(mock).toHaveBeenCalledWith({
      method: 'post',
      url: 'comments',
      data: expectedPayload,
    })
  })
})
