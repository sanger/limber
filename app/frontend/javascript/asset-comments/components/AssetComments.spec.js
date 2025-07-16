import AssetComments from './AssetComments.vue'
import {
  mountWithCommentFactory,
  testCommentFactoryInitAndDestroy,
} from '@/javascript/asset-comments/components/component-test-utils.js'
import eventBus from '@/javascript/shared/eventBus.js'
import { flushPromises } from '@vue/test-utils'

// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
describe('AssetComments', () => {
  testCommentFactoryInitAndDestroy(AssetComments, [
    { id: 1, text: 'Test comment', user: { login: 'js1', first_name: 'John', last_name: 'Smith' } },
  ])

  it('renders a list of comments', async () => {
    const mockComments = [
      {
        id: '1234',
        title: null,
        description: 'This is a comment',
        created_at: '2017-08-31T11:18:16+01:00',
        updated_at: '2017-08-31T11:18:16+01:00',
        user: {
          id: '12',
          login: 'js1',
          first_name: 'John',
          last_name: 'Smith',
        },
      },
      {
        id: '12345',
        title: null,
        description: 'This is also a comment',
        created_at: '2017-09-30T12:18:16+01:00',
        updated_at: '2017-09-30T12:18:16+01:00',
        user: {
          id: '13',
          login: 'js2',
          first_name: 'Jane',
          last_name: 'Smythe',
        },
      },
    ]
    const { wrapper } = mountWithCommentFactory(AssetComments, mockComments)
    await flushPromises()

    expect(wrapper.find('.comments-list').exists()).toBe(true)
    expect(wrapper.find('.comments-list').findAll('li').length).toBe(2)
    // checking sort of comments, should be re-ordered
    expect(wrapper.find('.comments-list').findAll('li')[0].text()).toContain('This is also a comment')
    expect(wrapper.find('.comments-list').findAll('li')[0].text()).toContain('Jane Smythe (js2)')
    expect(wrapper.find('.comments-list').findAll('li')[0].text()).toContain('30 September 2017 at 12:18')
    expect(wrapper.find('.comments-list').findAll('li')[1].text()).toContain('This is a comment')
    expect(wrapper.find('.comments-list').findAll('li')[1].text()).toContain('John Smith (js1)')
    expect(wrapper.find('.comments-list').findAll('li')[1].text()).toContain('31 August 2017 at 11:18')
  })

  it('renders a message when there are no comments', async () => {
    const { wrapper } = mountWithCommentFactory(AssetComments, [])
    await flushPromises()

    expect(wrapper.find('.comments-list').exists()).toBe(true)
    expect(wrapper.find('.comments-list').findAll('li').length).toBe(1)
    expect(wrapper.find('.comments-list').findAll('li.no-comment').length).toBe(1)
    expect(wrapper.find('.comments-list').find('li').text()).toContain('No comments available')
  })

  it('renders a spinner when comments are not loaded', () => {
    const { wrapper } = mountWithCommentFactory(AssetComments, null)

    expect(wrapper.find('.comments-list').exists()).toBe(true)
    expect(wrapper.find('.comments-list').find('.spinner-dark').exists()).toBe(true)
  })

  it('updates comments when eventBus emits update-comments', async () => {
    const { wrapper } = mountWithCommentFactory(AssetComments, [])
    await flushPromises()

    expect(wrapper.find('.comments-list').find('li').text()).toContain('No comments available')
    eventBus.$emit('update-comments', {
      assetId: '123',
      comments: [
        {
          id: '12345',
          title: null,
          description: 'This is also a comment',
          created_at: '2017-09-30T12:18:16+01:00',
          updated_at: '2017-09-30T12:18:16+01:00',
          user: {
            id: '13',
            login: 'js2',
            first_name: 'Jane',
            last_name: 'Smythe',
          },
        },
      ],
    })
    await wrapper.vm.$nextTick()
    expect(wrapper.find('.comments-list').findAll('li').length).toBe(1)
    expect(wrapper.find('.comments-list').find('li').text()).toContain('Jane Smythe (js2)')
  })

  it('does not update comments when eventBus emits update-comments for a different assetId', async () => {
    const { wrapper } = mountWithCommentFactory(AssetComments, [])
    await flushPromises()
    expect(wrapper.find('.comments-list').find('li').text()).toContain('No comments available')
    eventBus.$emit('update-comments', {
      assetId: '345',
      comments: [
        {
          id: 1,
          text: 'Test comment',
          user: {
            id: '13',
            login: 'js2',
            first_name: 'Jane',
            last_name: 'Smythe',
          },
        },
      ],
    })
    await wrapper.vm.$nextTick()
    expect(wrapper.find('.comments-list').find('li').text()).toContain('No comments available')
  })
})
