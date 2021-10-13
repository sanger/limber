// Import the component being tested
import localVue from 'test_support/base_vue'
import { mount } from '@vue/test-utils'
import AssetCommentsAddForm from './AssetCommentsAddForm.vue'

describe('AssetCommentsAddForm', () => {

  const wrapperFactory = function(comments) {
    const parent = {
      data() {
        return {
          comments,
          addComment() { },
          refreshComments() { }
        }
      }
    }

    return mount(AssetCommentsAddForm, { localVue, parentComponent: parent, propsData: { commentTitle: 'Test title' } })
  }

  it('correctly sets the state to pending when created', () => {
    let wrapper = wrapperFactory([])

    expect(wrapper.vm.state).toBe('pending')
  })

  it('renders a form for adding comments', () => {
    let wrapper = wrapperFactory([])

    expect(wrapper.find('textarea').exists()).toBe(true)
    expect(wrapper.find('textarea').text()).toEqual('')
    expect(wrapper.find('button').exists()).toBe(true)
    expect(wrapper.find('button').element.getAttribute('disabled')).toBeTruthy()
    expect(wrapper.find('button').text()).toEqual('Add Comment to Sequencescape')
  })

  it('enables the add comment submit button with valid input', async () => {
    let wrapper = wrapperFactory([])

    await wrapper.setData({ assetComment: 'Test comment', state: 'pending' })

    expect(wrapper.find('button').element.getAttribute('disabled')).toBeFalsy()
    expect(wrapper.find('button').text()).toEqual('Add Comment to Sequencescape')
  })

  it('disables the add comment submit button once submission has started', async () => {
    let wrapper = wrapperFactory([])

    wrapper.setData({ assetComment: 'Test comment', state: 'busy' })

    await wrapper.vm.$nextTick()

    expect(wrapper.find('button').element.getAttribute('disabled')).toBeTruthy()
    expect(wrapper.find('button').text()).toEqual('Sending...')
  })

  it('shows a success message on the button if adding was successful', async () => {
    let wrapper = wrapperFactory([])

    wrapper.setData({ state: 'success' })

    await wrapper.vm.$nextTick()

    expect(wrapper.find('button').element.getAttribute('disabled')).toBeTruthy()
    expect(wrapper.find('button').text()).toEqual('Comment successfully added')
  })

  it('shows a failure message on the button if adding was unsuccessful', async () => {
    let wrapper = wrapperFactory([])

    wrapper.setData({ state: 'failure' })

    await wrapper.vm.$nextTick()

    expect(wrapper.find('button').element.getAttribute('disabled')).toBeFalsy()
    expect(wrapper.find('button').text()).toEqual('Failed to add comment, retry?')
  })

  it('submits a comment via the comment store object on clicking the submit button', async () => {
    let wrapper = wrapperFactory([])
    wrapper.vm.$parent.addComment = jest.fn().mockResolvedValue(true)

    await wrapper.setData({ assetComment: 'Test comment' })

    expect(wrapper.vm.state).toEqual('pending')

    wrapper.find('button').element.click()

    expect(wrapper.vm.state).toEqual('busy')
    expect(wrapper.vm.$parent.addComment).toHaveBeenCalledWith('Test title', 'Test comment')
  })

  it('adding a comment updates the state and button text', async () => {
    let wrapper = wrapperFactory([])

    wrapper.vm.$parent.addComment = jest.fn().mockResolvedValue(true)

    await wrapper.setData({ assetComment: 'Test comment' })
    await wrapper.vm.submit()

    expect(wrapper.vm.state).toEqual('success')
    expect(wrapper.find('button').element.getAttribute('disabled')).toBeTruthy()
    expect(wrapper.find('button').text()).toEqual('Comment successfully added')
  })

  it('adding unsuccessfully updates the state and button text', async () => {
    let wrapper = wrapperFactory([])

    wrapper.vm.$parent.addComment = jest.fn().mockResolvedValue(false)

    await wrapper.setData({ assetComment: 'Test comment' })
    await wrapper.vm.submit()

    expect(wrapper.vm.state).toEqual('failure')
    expect(wrapper.find('button').element.getAttribute('disabled')).toBeFalsy()
    expect(wrapper.find('button').text()).toEqual('Failed to add comment, retry?')
  })

})
