// // Import the component being tested
import commentStoreFactory from './comment-store.js'
import flushPromises from 'flush-promises'
import axios from 'axios'
import MockAdapter from 'axios-mock-adapter'

describe('commentStore', () => {

  const noComments = { data: [] }
  const comments = { data: [
    {
      id: '1234',
      title: 'This is a title',
      description: 'This is a comment',
      created_at: '2017-08-31T11:18:16+01:00',
      updated_at: '2017-08-31T11:18:16+01:00',
      user: {
        id: '12',
        login: 'js1',
        first_name: 'John',
        last_name: 'Smith'
      }
    },
    {
      id: '12345',
      title: 'This is also a title',
      description: 'This is also a comment',
      created_at: '2017-09-30T11:18:16+01:00',
      updated_at: '2017-09-30T11:18:16+01:00',
      user: {
        id: '13',
        login: 'js2',
        first_name: 'Jane',
        last_name: 'Smythe'
      }
    }
  ]}

  const mockApiFactory = function(promise) {
    return {
      one(resource, id) {
        this.parents = [resource,id]
        return this
      },
      all(resource) {
        this.resouce = resource
        return this
      },
      get(options) {
        this.whered = options.filter
        this.included = options.include
        this.selected = options.select
        return this.promise
      },
      findAll(resource, options) {
        this.resource = resource
        this.whered = options.filter
        this.included = options.include
        this.selected = options.select
        return this.promise
      },
      promise: promise,
      whered: {},
      selected: [],
      included: []
    }
  }

  it('retrieves comments for an uncommented asset when prompted', async () => {
    let api = mockApiFactory(Promise.resolve(noComments))
    let commentStore = commentStoreFactory(null, api, '123', 'user_id')

    commentStore.refreshComments()

    await flushPromises()

    expect(api.included).toEqual('user')
    expect(api.parents).toEqual(['asset','123'])
    expect(commentStore.comments).toEqual([])

  })

  it('retrieves comments for a commented asset when prompted', async () => {
    let api = mockApiFactory(Promise.resolve(comments))
    let commentStore = commentStoreFactory(null, api, '123', 'user_id')

    commentStore.refreshComments()

    await flushPromises()

    expect(api.included).toEqual('user')
    expect(api.parents).toEqual(['asset','123'])
    expect(commentStore.comments.length).toEqual(2)

  })

  it('retrieves comments after adding a new comment', async () => {
    let api = mockApiFactory(Promise.resolve(comments))
    let mock = new MockAdapter(axios)
    let commentStore = commentStoreFactory(axios, api, '123', 'user_id')

    expect(commentStore.comments).toEqual(undefined)

    mock.onPost().reply((_config) =>{
      return [201, {}]
    })

    commentStore.addComment('new title', 'new description')

    await flushPromises()

    expect(commentStore.comments.length).toEqual(2)
  })

  it('posts comments to the sequencescape api', async () => {
    let api = mockApiFactory(Promise.resolve(comments))
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
            'data': { 'type': 'assets', 'id': '123' }
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
