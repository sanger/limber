// Import the component being tested
import { shallowMount } from '@vue/test-utils'

import AssetCommentsCounter from './AssetCommentsCounter.vue'

// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
describe('AssetCommentsCounter', () => {

  const wrapperFactory = function(comments) {
    const parent = {
      data() {
        return { comments }
      }
    }

    return shallowMount(AssetCommentsCounter, { parentComponent: parent })
  }

  it('renders a count of comments', () => {
    const wrapper = wrapperFactory([
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
          lastName: 'Smith'
        }
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
          lastName: 'Smythe'
        }
      }
    ])

    expect(wrapper.find('.badge.badge-success').exists()).toBe(true)
    expect(wrapper.find('.badge.badge-success').text()).toContain('2')
  })

  it('renders a greyed out zero indicating no comments', () => {
    const wrapper = wrapperFactory([])

    expect(wrapper.find('.badge.badge-secondary').exists()).toBe(true)
    expect(wrapper.find('.badge.badge-secondary').text()).toContain('0')
  })

  it('renders greyed out dots indicating searching for comments', () => {
    const wrapper = shallowMount(AssetCommentsCounter)

    expect(wrapper.find('.badge.badge-secondary').exists()).toBe(true)
    expect(wrapper.find('.badge.badge-secondary').text()).toContain('...')
  })

})
