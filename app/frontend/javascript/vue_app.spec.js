import { renderVueComponent, missingUserIdError } from './vue_app.js'
import { h } from 'vue'
import * as cookieJarLib from '@/javascript/shared/cookieJar.js'

describe('renderVueComponent', () => {
  let component, props, selector, element, userIdRequired

  beforeEach(() => {
    component = {
      name: 'TestComponent',
      render() {
        return h('div', 'Test string')
      },
    }
    props = { propA: 'valueA' }
    selector = 'test-selector'
    // Mock the CRSF token so the axios header can be set
    const meta = document.createElement('meta')
    meta.name = 'csrf-token'
    meta.content = 'mocked_csrf_token'
    document.head.appendChild(meta)

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
    const app = renderVueComponent(selector, component, props, userIdRequired)
    expect(app).toBeDefined()
    expect(document.body.innerHTML).toContain('Test string')
  })

  it('does not render the Vue component when element is not found', () => {
    document.body.innerHTML = ''
    const app = renderVueComponent(selector, component, props, userIdRequired)
    expect(app).toBeUndefined()
  })
  it('renders the Vue component when userId is required and found', () => {
    userIdRequired = true
    vi.spyOn(cookieJarLib, 'default').mockReturnValue({ user_id: 'mocked_user_id' })
    renderVueComponent(selector, component, props, userIdRequired)
    expect(document.body.innerHTML).toContain('Test string')
  })
  it('renders missingUserIdError when userId is required but not found', () => {
    vi.spyOn(cookieJarLib, 'default').mockReturnValue({ user_id: null })
    userIdRequired = true
    renderVueComponent(selector, component, props, userIdRequired)
    expect(document.body.innerHTML).toContain(missingUserIdError)
  })
  it('renders the Vue component when userId is not required and not found', () => {
    vi.spyOn(cookieJarLib, 'default').mockReturnValue({ user_id: null })
    renderVueComponent(selector, component, props, userIdRequired)
    expect(document.body.innerHTML).toContain('Test string')
  })
})
