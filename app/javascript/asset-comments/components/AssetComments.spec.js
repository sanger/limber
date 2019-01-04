// Import the component being tested
import { shallowMount } from '@vue/test-utils'

import AssetComments from './AssetComments.vue'

// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
describe('AssetComments', () => {

  const wrapperFactory = function(comments) {
    const parent = {
      data() {
        return { comments }
      }
    }

    return shallowMount(AssetComments, { parentComponent: parent })
  }

  it('renders a list of comments', () => {
    const wrapper = wrapperFactory([
      {
        id: '1234',
        title: null,
        description: 'This is a comment',
        createdAt: "2017-08-31T11:18:16+01:00",
        updatedAt: "2017-08-31T11:18:16+01:00",
        user: {
          id: '12',
          login: 'js1',
          firstName: 'John',
          lastName: 'Smith'
        }
      },
      {
        id: '12345',
        title: null,
        description: 'This is also a comment',
        createdAt: "2017-09-30T11:18:16+01:00",
        updatedAt: "2017-09-30T11:18:16+01:00",
        user: {
          id: '13',
          login: 'js2',
          firstName: 'Jane',
          lastName: 'Smythe'
        }
      }
    ])
    expect(wrapper.find('.comments-list').exists()).toBe(true)
    expect(wrapper.find('.comments-list').findAll('li').length).toBe(2)
    expect(wrapper.find('.comments-list').findAll('li').wrappers[0].text()).toContain('This is a comment')
    expect(wrapper.find('.comments-list').findAll('li').wrappers[0].text()).toContain('John Smith (js1)')
    expect(wrapper.find('.comments-list').findAll('li').wrappers[0].text()).toContain('31 August 2017, 11:18')
  })

  it('renders a message when there are no comments', () => {
    const wrapper = wrapperFactory([])
    expect(wrapper.find('.comments-list').exists()).toBe(true)
    expect(wrapper.find('.comments-list').findAll('li').length).toBe(1)
    expect(wrapper.find('.comments-list').findAll('li.no-comment').length).toBe(1)
    expect(wrapper.find('.comments-list').find('li').text()).toContain('No comments available')
  })

  it('renders a spinner when comments are not loaded', () => {
    const wrapper = shallowMount(AssetComments)
    expect(wrapper.find('.comments-list').exists()).toBe(true)
    expect(wrapper.find('.comments-list').find('.spinner-dark').exists()).toBe(true)
  })

})
