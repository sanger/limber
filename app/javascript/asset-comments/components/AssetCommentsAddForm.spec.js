// Import the component being tested
import { shallowMount } from '@vue/test-utils'

import AssetCommentsAddForm from './AssetCommentsAddForm.vue'
// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
describe('AssetCommentsAddForm', () => {

  const wrapperFactory = function(comments) {
    const parent = {
      data() {
        return { comments }
      }
    }

    return shallowMount(AssetCommentsAddForm, { parentComponent: parent })
  }

  it('renders a form for adding comments', () => {
    const wrapper = wrapperFactory([])

    expect(wrapper.find('.form-control').exists()).toBe(true)
    expect(wrapper.find('.btn.btn-success.btn-lg.btn-block').exists()).toBe(true)
  })
})
