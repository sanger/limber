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
        created_at: '2017-08-31T11:18:16+01:00',
        updated_at: '2017-08-31T11:18:16+01:00',
        user: {
          id: '12',
          login: 'js1',
          first_name: 'John',
          last_name: 'Smith'
        }
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
          last_name: 'Smythe'
        }
      }
    ])

    expect(wrapper.find('.comments-list').exists()).toBe(true)
    expect(wrapper.find('.comments-list').findAll('li').length).toBe(2)
    // checking sort of comments, should be re-ordered
    expect(wrapper.find('.comments-list').findAll('li').wrappers[0].text()).toContain('This is also a comment')
    expect(wrapper.find('.comments-list').findAll('li').wrappers[0].text()).toContain('Jane Smythe (js2)')
    expect(wrapper.find('.comments-list').findAll('li').wrappers[0].text()).toContain('30 September 2017, 12:18')
    expect(wrapper.find('.comments-list').findAll('li').wrappers[1].text()).toContain('This is a comment')
    expect(wrapper.find('.comments-list').findAll('li').wrappers[1].text()).toContain('John Smith (js1)')
    expect(wrapper.find('.comments-list').findAll('li').wrappers[1].text()).toContain('31 August 2017, 11:18')
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
