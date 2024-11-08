import { renderVueComponent, missingUserIdError } from './vue_app.js'
import * as cookieJarLib from '@/javascript/shared/cookieJar.js'

describe('renderVueComponent', () => {
  let component, props, data, selector, element, userIdRequired

  beforeEach(() => {
    component = {
      name: 'TestComponent',
      render(h) {
        return h('div', 'Test string')
      },
    }
    props = { propA: 'valueA' }
    data = { dataA: 'valueA' }
    selector = 'test-selector'
    element = document.createElement('div')
    element.id = selector
    document.body.appendChild(element)
    userIdRequired = false
    vi.spyOn(console, 'error').mockImplementation(() => {})
  })

  afterEach(() => {
    document.body.innerHTML = ''
  })

  it('renders the Vue component when element is found', () => {
    const app = renderVueComponent(selector, component, props, data, userIdRequired)
    expect(app).toBeDefined()
    expect(app.$el.innerHTML).toContain('Test string')
  })

  it('does not render the Vue component when element is not found', () => {
    document.body.innerHTML = ''
    const app = renderVueComponent(selector, component, props, data, userIdRequired)
    expect(app).toBeUndefined()
  })
  it('renders the Vue component when userId is required and found', () => {
    userIdRequired = true
    vi.spyOn(cookieJarLib, 'default').mockReturnValue({ user_id: 'mocked_user_id' })
    renderVueComponent(selector, component, props, data, userIdRequired)
    expect(document.body.innerHTML).toContain('Test string')
  })
  it('renders missingUserIdError when userId is required but not found', () => {
    vi.spyOn(cookieJarLib, 'default').mockReturnValue({ user_id: null })
    userIdRequired = true
    const app = renderVueComponent(selector, component, props, data, userIdRequired)
    expect(app.$el.innerHTML).toContain(missingUserIdError)
  })
  it('renders the Vue component when userId is not required and not found', () => {
    vi.spyOn(cookieJarLib, 'default').mockReturnValue({ user_id: null })
    const app = renderVueComponent(selector, component, props, data, userIdRequired)
    expect(app.$el.innerHTML).toContain('Test string')
  })
})
