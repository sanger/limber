// Import the component being tested
import AssetCommentsCounter from './AssetCommentsCounter.vue'
import eventBus from '@/javascript/shared/eventBus.js'
import {
  mountWithCommentFactory,
  testCommentFactoryInitAndDestroy,
} from '@/javascript/asset-comments/components/component-test-utils.js'
import { flushPromises } from '@vue/test-utils'

describe('AssetCommentsCounter', () => {
  testCommentFactoryInitAndDestroy(AssetCommentsCounter, [{ id: 1, text: 'Test comment' }])

  it('renders a count of comments', async () => {
    const mockComments = [
      {
        id: '1234',
        title: null,
        description: 'This is a comment',
        createdAt: '2017-08-31T11:18:16+01:00',
        updatedAt: '2017-08-31T11:18:16+01:00',
        user: {
          id: '12',
          login: 'js1',
          firstName: 'John',
          lastName: 'Smith',
        },
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
          lastName: 'Smythe',
        },
      },
    ]

    const { wrapper } = mountWithCommentFactory(AssetCommentsCounter, mockComments)

    await flushPromises()

    expect(wrapper.find('.badge.bg-success').exists()).toBe(true)
    expect(wrapper.find('.badge.bg-success').text()).toContain('2')
  })

  it('renders a greyed out zero indicating no comments', async () => {
    const { wrapper } = mountWithCommentFactory(AssetCommentsCounter, [])
    await flushPromises()

    expect(wrapper.find('.badge.bg-secondary').exists()).toBe(true)
    expect(wrapper.find('.badge.bg-secondary').text()).toContain('0')
  })

  it('renders greyed out dots indicating searching for comments', () => {
    const { wrapper } = mountWithCommentFactory(AssetCommentsCounter)

    expect(wrapper.find('.badge.bg-secondary').exists()).toBe(true)
    expect(wrapper.find('.badge.bg-secondary').text()).toContain('...')
  })

  it('updates comments when eventBus emits update-comments', async () => {
    const { wrapper } = mountWithCommentFactory(AssetCommentsCounter, [])
    await flushPromises()

    expect(wrapper.find('.badge.bg-secondary').text()).toContain('0')
    eventBus.$emit('update-comments', { assetId: '123', comments: [{ id: 1, text: 'Test comment' }] })
    await wrapper.vm.$nextTick()
    expect(wrapper.find('.badge.bg-success').text()).toContain('1')
  })
  it('does not update comments when eventBus emits update-comments for a different assetId', async () => {
    const { wrapper } = mountWithCommentFactory(AssetCommentsCounter, [])
    await flushPromises()

    expect(wrapper.find('.badge.bg-secondary').text()).toContain('0')
    eventBus.$emit('update-comments', { assetId: '456', comments: [{ id: 1, text: 'Test comment' }] })
    await wrapper.vm.$nextTick()
    expect(wrapper.find('.badge.bg-secondary').text()).toContain('0')
  })
})
