// // Import the component being tested
import { jsonFactory } from './factories'

describe('jsonFactory', () => {
  // Using comments as a simple example
  it('generates a simple model without inlined data', () => {
    const json = jsonFactory('comment', {
      id: '123',
      created_at: '2018-07-06T13:39:32+01:00',
      updated_at: '2018-07-06T13:39:32+01:00'
    })

    expect(json).toEqual({
      'data': {
        'id': '123',
        'type': 'comments',
        'links': {
          'self': 'http://www.example.com/comments/123'
        },
        'attributes': {
          'title': 'Comment Title',
          'description': 'This is a comment',
          'created_at': '2018-07-06T13:39:32+01:00',
          'updated_at': '2018-07-06T13:39:32+01:00'
        },
        'relationships': {
          'user': {
            'links': {
              'self': 'http://www.example.com/comments/123/relationships/user',
              'related': 'http://www.example.com/comments/123/user'
            }
          },
          'commentable': {
            'links': {
              'self': 'http://www.example.com/comments/123/relationships/commentable',
              'related': 'http://www.example.com/comments/123/commentable'
            }
          }
        },
        // In practice the include array doesn't appear when empty. I'm not replicating
        // that behaviour here for reasons of keeping the code simple.
        'included': []
      }
    })
  })

  it('generates a default id', () =>{
    const json = jsonFactory('user')

    expect(json.data.id).toMatch(/^[0-9]+$/)
  })

  it('generates a default uuid', () =>{
    const json = jsonFactory('user')

    expect(json.data.attributes.uuid).toMatch(/^[a-f\d]{8}-([a-f\d]{4}-){3}[a-f\d]{12}$/)
  })

  it('generates a default created_at', () =>{
    const json = jsonFactory('comment')

    expect(json.data.attributes.created_at).toBeTruthy()
  })

  it('generates inline data where appropriate', () => {
    const userUuid = 'bb1de498-88d6-4545-bf61-f37031db5fdb'
    const json = jsonFactory('comment', {
      id: '123',
      created_at: '2018-07-06T13:39:32+01:00',
      updated_at: '2018-07-06T13:39:32+01:00',
      user: { _factory: 'custom_user', uuid: userUuid, id: '456' }
    })

    expect(json).toEqual({
      'data': {
        'id': '123',
        'type': 'comments',
        'links': {
          'self': 'http://www.example.com/comments/123'
        },
        'attributes': {
          'title': 'Comment Title',
          'description': 'This is a comment',
          'created_at': '2018-07-06T13:39:32+01:00',
          'updated_at': '2018-07-06T13:39:32+01:00'
        },
        'relationships': {
          'user': {
            'links': {
              'self': 'http://www.example.com/comments/123/relationships/user',
              'related': 'http://www.example.com/comments/123/user'
            },
            'data': { 'type': 'users', 'id': '456'}
          },
          'commentable': {
            'links': {
              'self': 'http://www.example.com/comments/123/relationships/commentable',
              'related': 'http://www.example.com/comments/123/commentable'
            }
          }
        },
        'included': [
          {
            'id': '456',
            'type': 'users',
            'links': {
              'self': 'http://www.example.com/users/456'
            },
            'attributes': {
              'uuid': userUuid,
              'login': 'js',
              'first_name': 'Jane',
              'last_name': 'Smith'
            },
            'relationships': {}
          }
        ]
      }
    })
  })
})
