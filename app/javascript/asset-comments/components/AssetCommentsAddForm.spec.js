// Import the component being tested
import localVue from 'test_support/base_vue.js'
import { mount } from '@vue/test-utils'
import flushPromises from 'flush-promises'
import AssetCommentsAddForm from './AssetCommentsAddForm.vue'

// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
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

  it('enables the add comment submit button with valid input', () => {
    let wrapper = wrapperFactory([])

    wrapper.setData({ assetComment: 'Test comment', state: 'pending' })

    expect(wrapper.find('button').element.getAttribute('disabled')).toBeFalsy()
    expect(wrapper.find('button').text()).toEqual('Add Comment to Sequencescape')
  })

  it('disables the add comment submit button once submission has started', () => {
    let wrapper = wrapperFactory([])

    wrapper.setData({ assetComment: 'Test comment', state: 'busy' })

    expect(wrapper.find('button').element.getAttribute('disabled')).toBeTruthy()
    expect(wrapper.find('button').text()).toEqual('Sending...')
  })

  it('shows a success message on the button if adding was successful', () => {
    let wrapper = wrapperFactory([])

    wrapper.setData({ state: 'success' })

    expect(wrapper.find('button').element.getAttribute('disabled')).toBeTruthy()
    expect(wrapper.find('button').text()).toEqual('Comment successfully added')
  })

  it('shows a failure message on the button if adding was unsuccessful', () => {
    let wrapper = wrapperFactory([])

    wrapper.setData({ state: 'failure' })

    expect(wrapper.find('button').element.getAttribute('disabled')).toBeFalsy()
    expect(wrapper.find('button').text()).toEqual('Failed to add comment, retry?')
  })

  it('submits a comment via the comment store object on clicking the submit button', () => {
    let wrapper = wrapperFactory([])

    wrapper.setData({ assetComment: 'Test comment' })

    spyOn(wrapper.vm.$parent, 'addComment')

    expect(wrapper.vm.state).toEqual('pending')

    wrapper.find('button').element.click()

    expect(wrapper.vm.state).toEqual('busy')
    expect(wrapper.vm.$parent.addComment).toHaveBeenCalledWith('Test title', 'Test comment')
  })

  it('adding a comment updates the state and button text', async () => {
    let wrapper = wrapperFactory([])

    spyOn(wrapper.vm.$parent, 'addComment').and.returnValue(true)

    wrapper.setData({ assetComment: 'Test comment' })
    wrapper.vm.submit()

    await flushPromises()

    expect(wrapper.vm.state).toEqual('success')
    expect(wrapper.find('button').element.getAttribute('disabled')).toBeTruthy()
    expect(wrapper.find('button').text()).toEqual('Comment successfully added')
  })

  it('adding unsuccessfully updates the state and button text', async () => {
    let wrapper = wrapperFactory([])

    spyOn(wrapper.vm.$parent, 'addComment').and.returnValue(false)

    wrapper.setData({ assetComment: 'Test comment' })
    wrapper.vm.submit()

    await flushPromises()

    expect(wrapper.vm.state).toEqual('failure')
    expect(wrapper.find('button').element.getAttribute('disabled')).toBeFalsy()
    expect(wrapper.find('button').text()).toEqual('Failed to add comment, retry?')
  })

})
