// Import the component being tested
import localVue from 'test_support/base_vue.js'
import { mount } from '@vue/test-utils'

import AssetCommentsAddForm from './AssetCommentsAddForm.vue'
// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
describe('AssetCommentsAddForm', () => {

  const wrapperFactory = function(comments) {
    const parent = {
      data() {
        return {
          comments,
          addComment(newTitle, newDescription) { }
        }
      }
    }

    return mount(AssetCommentsAddForm, { localVue, parentComponent: parent, propsData: { commentTitle: 'Test title' } })
  }

  it('correctly sets the state when created', () => {
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

  it('submits a comment on clicking the submit button', () => {
    let wrapper = wrapperFactory([])

    wrapper.setData({ assetComment: 'Test comment' })

    wrapper.find('button').element.click()

    expect(wrapper.vm.state).toEqual('busy')
  })

  // TODO: need a test for successful submission
  // TODO: need a test for a failed submission
})
