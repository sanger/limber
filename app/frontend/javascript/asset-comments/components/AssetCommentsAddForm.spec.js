// Import the component being tested

import AssetCommentsAddForm from './AssetCommentsAddForm.vue'
import { mountWithCommentFactory } from '@/javascript/asset-comments/components/component-test-utils.js'

describe('AssetCommentsAddForm', () => {
  it('correctly sets the state to pending when created', () => {
    const { wrapper } = mountWithCommentFactory(AssetCommentsAddForm, [], { commentTitle: 'Test title' })
    expect(wrapper.vm.state).toBe('pending')
  })

  it('renders a form for adding comments', () => {
    const { wrapper } = mountWithCommentFactory(AssetCommentsAddForm, [], { commentTitle: 'Test title' })
    expect(wrapper.find('textarea').exists()).toBe(true)
    expect(wrapper.find('textarea').text()).toEqual('')
    expect(wrapper.find('button').exists()).toBe(true)
    expect(wrapper.find('button').element.disabled).toBeTruthy()
    expect(wrapper.find('button').text()).toEqual('Add Comment to Sequencescape')
  })

  it('enables the add comment submit button with valid input', async () => {
    const { wrapper } = mountWithCommentFactory(AssetCommentsAddForm, [], { commentTitle: 'Test title' })
    await wrapper.setData({ assetComment: 'Test comment', state: 'pending' })

    expect(wrapper.find('button').element.disabled).toBeFalsy()
    expect(wrapper.find('button').text()).toEqual('Add Comment to Sequencescape')
  })

  it('disables the add comment submit button once submission has started', async () => {
    const { wrapper } = mountWithCommentFactory(AssetCommentsAddForm, [], { commentTitle: 'Test title' })
    wrapper.setData({ assetComment: 'Test comment', state: 'busy' })

    await wrapper.vm.$nextTick()

    expect(wrapper.find('button').element.disabled).toBeTruthy()
    expect(wrapper.find('button').text()).toEqual('Sending...')
  })

  it('shows a success message on the button if adding was successful', async () => {
    const { wrapper } = mountWithCommentFactory(AssetCommentsAddForm, [], { commentTitle: 'Test title' })
    wrapper.setData({ state: 'success' })

    await wrapper.vm.$nextTick()

    expect(wrapper.find('button').element.disabled).toBeTruthy()
    expect(wrapper.find('button').text()).toEqual('Comment successfully added')
  })

  it('shows a failure message on the button if adding was unsuccessful', async () => {
    const { wrapper } = mountWithCommentFactory(AssetCommentsAddForm, [], { commentTitle: 'Test title' })
    wrapper.setData({ state: 'failure' })

    await wrapper.vm.$nextTick()

    expect(wrapper.find('button').element.disabled).toBeFalsy()
    expect(wrapper.find('button').text()).toEqual('Failed to add comment, retry?')
  })

  it('submits a comment via the comment store object on clicking the submit button', async () => {
    const { wrapper } = mountWithCommentFactory(AssetCommentsAddForm, [], { commentTitle: 'Test title' })

    wrapper.vm.commentFactory.addComment = vi.fn().mockResolvedValue(true)
    await wrapper.setData({ assetComment: 'Test comment' })
    expect(wrapper.vm.state).toEqual('pending')

    wrapper.find('button').element.click()

    expect(wrapper.vm.state).toEqual('busy')
    expect(wrapper.vm.commentFactory.addComment).toHaveBeenCalledWith('Test title', 'Test comment')
  })

  it('adding a comment updates the state and button text', async () => {
    const { wrapper } = mountWithCommentFactory(AssetCommentsAddForm, [], { commentTitle: 'Test title' })

    wrapper.vm.commentFactory.addComment = vi.fn().mockResolvedValue(true)

    await wrapper.setData({ assetComment: 'Test comment' })
    await wrapper.vm.submit()

    expect(wrapper.vm.state).toEqual('success')
    expect(wrapper.find('button').element.disabled).toBeTruthy()
    expect(wrapper.find('button').text()).toEqual('Comment successfully added')
  })

  it('adding unsuccessfully updates the state and button text', async () => {
    const { wrapper } = mountWithCommentFactory(AssetCommentsAddForm, [], { commentTitle: 'Test title' })
    wrapper.vm.commentFactory.addComment = vi.fn().mockResolvedValue(false)

    await wrapper.setData({ assetComment: 'Test comment' })
    await wrapper.vm.submit()

    expect(wrapper.vm.state).toEqual('failure')
    expect(wrapper.find('button').element.disabled).toBeFalsy()
    expect(wrapper.find('button').text()).toEqual('Failed to add comment, retry?')
  })
  it('removes eventBus listener on unmount', () => {
    const { wrapper, removeCommentFactoryMockFn } = mountWithCommentFactory(AssetCommentsAddForm, [], {
      commentTitle: 'Test title',
    })
    wrapper.unmount()
    expect(removeCommentFactoryMockFn).toHaveBeenCalled()
  })
})
