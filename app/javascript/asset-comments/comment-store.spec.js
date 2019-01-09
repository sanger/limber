// // Import the component being tested
import commentStoreFactory from './comment-store.js'
import { plateFactory } from 'test_support/factories.js'
import flushPromises from 'flush-promises'
import axios from 'axios'
import MockAdapter from 'axios-mock-adapter'

describe('commentStore', () => {

  const uncommentedPlate = { data: plateFactory({ comments: [] }) }
  const commentedPlate = { data: plateFactory({ comments: [{
    id: '1234',
    title: null,
    description: 'This is a comment',
    createdAt: '2017-08-31T11:18:16+01:00',
    updatedAt: '2017-08-31T11:18:16+01:00',
    user: {
      id: '12',
      login: 'js1',
      firstName: 'John',
      lastName: 'Smith'
    }
  },
  {
    id: '12345',
    title: null,
    description: 'This is also a comment',
    createdAt: '2017-09-30T11:18:16+01:00',
    updatedAt: '2017-09-30T11:18:16+01:00',
    user: {
      id: '13',
      login: 'js2',
      firstName: 'Jane',
      lastName: 'Smythe'
    }
  }]
  })
  }
  const mockApiFactory = function(promise) {
    return {
      includes(options) {
        this.included = options
        return this
      },
      select(options) {
        this.selected = options
        return this
      },
      find(id) {
        this.found = id
        return this.promise
      },
      promise: promise,
      found: undefined,
      selected: [],
      included: []
    }
  }

  // api.Plate.includes({ comments: 'user' }).find('23231887').then(function(result){ console.log(result) })

  it('retrieves comments for an uncommented asset when prompted', async () => {
    let api = mockApiFactory(Promise.resolve(uncommentedPlate))
    let commentStore = commentStoreFactory(null, api, '123', 'user_id')

    commentStore.refreshComments()

    await flushPromises()

    expect(api.included).toEqual({ comments: 'user' })
    expect(api.found).toEqual('123')
    expect(commentStore.comments).toEqual([])

  })

  it('retrieves comments for a commented asset when prompted', async () => {
    let api = mockApiFactory(Promise.resolve(commentedPlate))
    let commentStore = commentStoreFactory(null, api, '123', 'user_id')

    commentStore.refreshComments()

    await flushPromises()

    expect(api.included).toEqual({ comments: 'user' })
    expect(api.found).toEqual('123')
    expect(commentStore.comments.length).toEqual(2)

  })

  it('retrieves comments after adding a new comment', async () => {
    let api = mockApiFactory(Promise.resolve(commentedPlate))
    let mock = new MockAdapter(axios)
    let commentStore = commentStoreFactory(axios, api, '123', 'user_id')

    expect(commentStore.comments).toEqual(undefined)

    mock.onPost().reply((_config) =>{
      return [201, {}]
    })

    commentStore.addComment('new description')

    await flushPromises()

    expect(commentStore.comments.length).toEqual(2)
  })

  it('posts comments to the sequencescape api', async () => {
    let api = mockApiFactory(Promise.resolve(commentedPlate))
    let mock = new MockAdapter(axios)
    let commentStore = commentStoreFactory(axios, api, '123', 'user_id')

    const expectedPayload = {
      'data': {
        'type': 'comments',
        'attributes': {
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

    commentStore.addComment('new description')

    await flushPromises()

    expect(mock.history.post.length).toBe(1);
  })
})
