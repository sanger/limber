// // Import the component being tested
import { jsonFactory, jsonCollectionFactory } from './json_factory'

describe('jsonFactory', () => {
  it('generates a default id', () => {
    const json = jsonFactory('user')

    expect(json.data.id).toMatch(/^[0-9]+$/)
  })

  it('generates a default uuid', () => {
    const json = jsonFactory('user')

    expect(json.data.attributes.uuid).toMatch(/^[a-f\d]{8}-([a-f\d]{4}-){3}[a-f\d]{12}$/)
  })

  it('generates a default created_at', () => {
    const json = jsonFactory('comment')

    expect(json.data.attributes.created_at).toBeTruthy()
  })

  // Using comments as a simple example
  it('generates a simple model without inlined data', () => {
    const json = jsonFactory('comment', {
      id: '123',
      created_at: '2018-07-06T13:39:32+01:00',
      updated_at: '2018-07-06T13:39:32+01:00',
    })

    expect(json).toEqual({
      data: {
        id: '123',
        type: 'comments',
        links: {
          self: 'http://www.example.com/comments/123',
        },
        attributes: {
          title: 'Comment Title',
          description: 'This is a comment',
          created_at: '2018-07-06T13:39:32+01:00',
          updated_at: '2018-07-06T13:39:32+01:00',
        },
        relationships: {
          user: {
            links: {
              self: 'http://www.example.com/comments/123/relationships/user',
              related: 'http://www.example.com/comments/123/user',
            },
          },
          commentable: {
            links: {
              self: 'http://www.example.com/comments/123/relationships/commentable',
              related: 'http://www.example.com/comments/123/commentable',
            },
          },
        },
      },
      // In practice the include array doesn't appear when empty. I'm not replicating
      // that behaviour here for reasons of keeping the code simple.
      included: [],
    })
  })

  it('generates hasOne inline data', () => {
    const userUuid = 'bb1de498-88d6-4545-bf61-f37031db5fdb'
    const json = jsonFactory('comment', {
      id: '123',
      created_at: '2018-07-06T13:39:32+01:00',
      updated_at: '2018-07-06T13:39:32+01:00',
      user: { _factory: 'custom_user', uuid: userUuid, id: '456' },
    })

    expect(json).toEqual({
      data: {
        id: '123',
        type: 'comments',
        links: {
          self: 'http://www.example.com/comments/123',
        },
        attributes: {
          title: 'Comment Title',
          description: 'This is a comment',
          created_at: '2018-07-06T13:39:32+01:00',
          updated_at: '2018-07-06T13:39:32+01:00',
        },
        relationships: {
          user: {
            links: {
              self: 'http://www.example.com/comments/123/relationships/user',
              related: 'http://www.example.com/comments/123/user',
            },
            data: { type: 'users', id: '456' },
          },
          commentable: {
            links: {
              self: 'http://www.example.com/comments/123/relationships/commentable',
              related: 'http://www.example.com/comments/123/commentable',
            },
          },
        },
      },
      included: [
        {
          id: '456',
          type: 'users',
          links: {
            self: 'http://www.example.com/users/456',
          },
          attributes: {
            uuid: userUuid,
            login: 'js',
            first_name: 'Jane',
            last_name: 'Smith',
          },
          relationships: {},
        },
      ],
    })
  })

  it('generates hasMany inline data', () => {
    const uuid = 'bb1de498-88d6-4545-bf61-f37031db5fdb'
    const json = jsonFactory('asset', {
      id: '123',
      uuid,
      comments: [
        {
          id: '124',
          created_at: '2018-07-06T13:39:32+01:00',
          updated_at: '2018-07-06T13:39:32+01:00',
        },
        {
          id: '125',
          title: 'Comment 2',
          created_at: '2018-07-06T13:39:32+01:00',
          updated_at: '2018-07-06T13:39:32+01:00',
        },
      ],
    })

    expect(json).toEqual({
      data: {
        id: '123',
        type: 'assets',
        links: {
          self: 'http://www.example.com/assets/123',
        },
        attributes: {
          uuid: uuid,
        },
        relationships: {
          custom_metadatum_collection: {
            links: {
              self: 'http://www.example.com/assets/123/relationships/custom_metadatum_collection',
              related: 'http://www.example.com/assets/123/custom_metadatum_collection',
            },
          },
          comments: {
            links: {
              self: 'http://www.example.com/assets/123/relationships/comments',
              related: 'http://www.example.com/assets/123/comments',
            },
            data: [
              { id: '124', type: 'comments' },
              { id: '125', type: 'comments' },
            ],
          },
        },
      },
      included: [
        {
          id: '124',
          type: 'comments',
          links: {
            self: 'http://www.example.com/comments/124',
          },
          attributes: {
            title: 'Comment Title',
            description: 'This is a comment',
            created_at: '2018-07-06T13:39:32+01:00',
            updated_at: '2018-07-06T13:39:32+01:00',
          },
          relationships: {
            user: {
              links: {
                self: 'http://www.example.com/comments/124/relationships/user',
                related: 'http://www.example.com/comments/124/user',
              },
            },
            commentable: {
              links: {
                self: 'http://www.example.com/comments/124/relationships/commentable',
                related: 'http://www.example.com/comments/124/commentable',
              },
            },
          },
        },
        {
          id: '125',
          type: 'comments',
          links: {
            self: 'http://www.example.com/comments/125',
          },
          attributes: {
            title: 'Comment 2',
            description: 'This is a comment',
            created_at: '2018-07-06T13:39:32+01:00',
            updated_at: '2018-07-06T13:39:32+01:00',
          },
          relationships: {
            user: {
              links: {
                self: 'http://www.example.com/comments/125/relationships/user',
                related: 'http://www.example.com/comments/125/user',
              },
            },
            commentable: {
              links: {
                self: 'http://www.example.com/comments/125/relationships/commentable',
                related: 'http://www.example.com/comments/125/commentable',
              },
            },
          },
        },
      ],
    })
  })
})

describe('jsonCollectionFactory', () => {
  // Using comments as a simple example
  it('generates a collection without inlined data', () => {
    const json = jsonCollectionFactory(
      'comment',
      [
        {
          id: '124',
          created_at: '2018-07-06T13:39:32+01:00',
          updated_at: '2018-07-06T13:39:32+01:00',
        },
        {
          id: '125',
          title: 'Comment 2',
          created_at: '2018-07-06T13:39:32+01:00',
          updated_at: '2018-07-06T13:39:32+01:00',
        },
      ],
      {
        base: 'assets/123/comments',
      }
    )

    expect(json).toEqual({
      data: [
        {
          id: '124',
          type: 'comments',
          links: {
            self: 'http://www.example.com/comments/124',
          },
          attributes: {
            title: 'Comment Title',
            description: 'This is a comment',
            created_at: '2018-07-06T13:39:32+01:00',
            updated_at: '2018-07-06T13:39:32+01:00',
          },
          relationships: {
            user: {
              links: {
                self: 'http://www.example.com/comments/124/relationships/user',
                related: 'http://www.example.com/comments/124/user',
              },
            },
            commentable: {
              links: {
                self: 'http://www.example.com/comments/124/relationships/commentable',
                related: 'http://www.example.com/comments/124/commentable',
              },
            },
          },
        },
        {
          id: '125',
          type: 'comments',
          links: {
            self: 'http://www.example.com/comments/125',
          },
          attributes: {
            title: 'Comment 2',
            description: 'This is a comment',
            created_at: '2018-07-06T13:39:32+01:00',
            updated_at: '2018-07-06T13:39:32+01:00',
          },
          relationships: {
            user: {
              links: {
                self: 'http://www.example.com/comments/125/relationships/user',
                related: 'http://www.example.com/comments/125/user',
              },
            },
            commentable: {
              links: {
                self: 'http://www.example.com/comments/125/relationships/commentable',
                related: 'http://www.example.com/comments/125/commentable',
              },
            },
          },
        },
      ],
      // In practice the include array doesn't appear when empty. I'm not replicating
      // that behaviour here for reasons of keeping the code simple.
      included: [],
      links: {
        first: 'http://www.example.com/assets/123/comments?page%5Bnumber%5D=1&page%5Bsize%5D=100',
        last: 'http://www.example.com/assets/123/comments?page%5Bnumber%5D=1&page%5Bsize%5D=100',
      },
    })
  })
})
