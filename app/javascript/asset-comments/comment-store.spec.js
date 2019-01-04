// // Import the component being tested
import commentStoreFactory from './comment-store.js'
import { plateFactory } from 'test_support/factories.js'
import flushPromises from 'flush-promises'

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
    let commentStore = commentStoreFactory(api, '123')

    commentStore.refreshComments()

    await flushPromises()

    expect(api.included).toEqual({ comments: 'user' })
    expect(api.found).toEqual('123')
    expect(commentStore.comments).toEqual([])

  })

  it('retrieves comments for a commented asset when prompted', async () => {
    let api = mockApiFactory(Promise.resolve(commentedPlate))
    let commentStore = commentStoreFactory(api, '123')

    commentStore.refreshComments()

    await flushPromises()

    expect(api.included).toEqual({ comments: 'user' })
    expect(api.found).toEqual('123')
    expect(commentStore.comments.length).toEqual(2)

  })
})
