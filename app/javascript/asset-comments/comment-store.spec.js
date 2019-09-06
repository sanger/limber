// // Import the component being tested
import commentStoreFactory from './comment-store.js'
import flushPromises from 'flush-promises'
import axios from 'axios'
import MockAdapter from 'axios-mock-adapter'
import mockApi from 'test_support/mock_api'
import { jsonCollectionFactory } from 'test_support/factories'

describe('commentStore', () => {

  const noComments = { data: [] }
  const comments = jsonCollectionFactory('comment',[{
    title: 'This is a title',
    description: 'This is a comment',
    created_at: '2017-08-31T11:18:16+01:00',
    updated_at: '2017-08-31T11:18:16+01:00',
    user: {
      login: 'js1',
      first_name: 'John',
      last_name: 'Smith'
    }
  },{
    title: 'This is also a title',
    description: 'This is also a comment',
    created_at: '2017-09-30T11:18:16+01:00',
    updated_at: '2017-09-30T11:18:16+01:00',
    user: {
      login: 'js2',
      first_name: 'Jane',
      last_name: 'Smythe'
    }
  }])

  const mockApiFactory = function(response) {
    let api = mockApi()
    api.mockGet('labware/123/comments', {include: 'user'}, response)
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
    let mock = new MockAdapter(axios)
    let commentStore = commentStoreFactory(axios, api, '123', 'user_id')

    expect(commentStore.comments).toEqual(undefined)

    mock.onPost().reply((_) =>{
      return [201, {}]
    })

    commentStore.addComment('new title', 'new description')

    await flushPromises()

    expect(commentStore.comments.length).toEqual(2)
  })

  it('posts comments to the sequencescape api', async () => {
    let api = mockApiFactory(comments)
    let mock = new MockAdapter(axios)
    let commentStore = commentStoreFactory(axios, api, '123', 'user_id')

    const expectedPayload = {
      'data': {
        'type': 'comments',
        'attributes': {
          'title': 'new title',
          'description': 'new description'
        },
        'relationships': {
          'commentable': {
            'data': { 'type': 'labware', 'id': '123' }
          },
          'user': {
            'data': { 'type': 'users', 'id': 'user_id' }
          }
        }
      }
    }

    mock.onPost().reply((request) =>{
      // NB in practice the axios instance is configured to the sequencescape baseURL
      // whereas the mock adapter doesn't expose this
      expect(request.url).toEqual('comments')
      expect(request.data).toEqual(JSON.stringify(expectedPayload))
      return [201, {}]
    })

    commentStore.addComment('new title', 'new description')

    await flushPromises()

    expect(mock.history.post.length).toBe(1)
  })
})
