// Import the component being tested
import { shallowMount } from '@vue/test-utils'

import AssetCommentsAddForm from './AssetCommentsAddForm.vue'
// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
describe('AssetCommentsAddForm', () => {

  const wrapperFactory = function(comments) {
    const parent = {
      data() {
        return {
          comments,
          addComment(newDescription) { this.commentAdded = newDescription }
        }
      }
    }

    return shallowMount(AssetCommentsAddForm, { parentComponent: parent })
  }

  it('renders a form for adding comments', () => {
    let wrapper = wrapperFactory([])

    expect(wrapper.find('.form-control').exists()).toBe(true)
    expect(wrapper.find('.btn.btn-success.btn-lg.btn-block').exists()).toBe(true)
    expect(wrapper.find('.btn').element.getAttribute('disabled')).toBeTruthy()
  })

  it('enables the add comment submit button with valid input', () => {
    let wrapper = wrapperFactory([])

    wrapper.setData({ assetComment: 'Test comment' })

    expect(wrapper.find('.btn').element.getAttribute('disabled')).toBeFalsy()
  })

  it('disables the add comment submit button when submission started', () => {
    let wrapper = wrapperFactory([])

    wrapper.setData({ assetComment: 'Test comment', inProgress: true })

    expect(wrapper.find('.btn').element.getAttribute('disabled')).toBeTruthy()
  })

  it('submits a comment on clicking the submit button', () => {
    let wrapper = wrapperFactory()

    wrapper.setData({ assetComment: 'Test comment' })

    wrapper.find('.btn').element.click()

    expect(wrapper.vm.$root.$data.commentAdded).toEqual('Test comment')
  })
})
