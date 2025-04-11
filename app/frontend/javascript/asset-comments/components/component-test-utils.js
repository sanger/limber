import { mount } from '@vue/test-utils'
import * as commentStoreHelpers from '@/javascript/asset-comments/comment-store-helpers.js'
import eventBus from '@/javascript/shared/eventBus.js'

const commentProps = {
  sequencescapeApi: 'http://example.com/api',
  sequencescapeApiKey: 'test-api-key',
  assetId: '123',
  userId: 'user_id',
}

const mountWithCommentFactory = function (Component, comments, props = {}) {
  const mockRefreshComments = vi.fn().mockResolvedValue()
  const mockCommentFactory = {
    refreshComments: mockRefreshComments,
    addComments: vi.fn(),
    comments,
  }

  const removeCommentFactoryMockFn = vi.fn()
  vi.spyOn(commentStoreHelpers, 'createCommentFactory').mockReturnValue(mockCommentFactory)
  vi.spyOn(commentStoreHelpers, 'removeCommentFactory').mockImplementation(removeCommentFactoryMockFn)
  const wrapper = mount(Component, {
    props: { ...commentProps, ...props },
  })

  return { wrapper, mockCommentFactory, removeCommentFactoryMockFn }
}

function testCommentFactoryInitAndDestroy(Component, mockComments, props) {
  it('should initialize commentFactory and update comments on mount', async () => {
    const { wrapper, mockCommentFactory } = mountWithCommentFactory(Component, mockComments, props)

    await wrapper.vm.$nextTick()

    expect(commentStoreHelpers.createCommentFactory).toHaveBeenCalledWith(commentProps)
    expect(mockCommentFactory.refreshComments).toHaveBeenCalled()
    expect(wrapper.vm.comments).toEqual(mockComments)
  })

  it('removes eventBus listener on unmount', () => {
    vi.spyOn(eventBus, '$off')
    const { wrapper, removeCommentFactoryMockFn } = mountWithCommentFactory(Component, mockComments, props)
    wrapper.unmount()
    expect(eventBus.$off).toHaveBeenCalledWith('update-comments')
    expect(removeCommentFactoryMockFn).toHaveBeenCalled()
  })
}

export { mountWithCommentFactory, testCommentFactoryInitAndDestroy }
