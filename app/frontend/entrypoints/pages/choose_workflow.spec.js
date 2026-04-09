describe('choose_workflow submission form project fields', () => {
  const waitForCondition = async (predicate, timeoutMs = 1000, intervalMs = 10) => {
    const start = Date.now()

    while (Date.now() - start < timeoutMs) {
      if (predicate()) return
      await new Promise((resolve) => setTimeout(resolve, intervalMs))
    }

    throw new Error('Timed out waiting for async workflow update')
  }

  beforeEach(() => {
    document.body.innerHTML = `
      <div id="choose_workflow_card">
        <input id="project_cost_code_global" type="text" />
        <div id="project_search_result"></div>
        <div id="submission_forms">
          <form>
            <input type="hidden" class="project-cost-code-hidden" />
            <input type="hidden" class="supplied-project-uuid-hidden" />
          </form>
        </div>
      </div>
    `
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('sets hidden project fields when the form is submitted', async () => {
    vi.resetModules()

    const projectInput = document.getElementById('project_cost_code_global')
    const resultDiv = document.getElementById('project_search_result')
    const form = document.querySelector('#submission_forms form')
    const hiddenProjectCode = form.querySelector('.project-cost-code-hidden')
    const hiddenProjectUuid = form.querySelector('.supplied-project-uuid-hidden')

    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        json: vi.fn().mockResolvedValue({
          found: true,
          project: { uuid: 'project-uuid-123', name: 'Example Project' },
        }),
      }),
    )

    await import('./choose_workflow.js')

    projectInput.value = '12345'
    projectInput.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }))
    await waitForCondition(() => resultDiv.textContent === 'Project found: Example Project')

    form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))

    expect(hiddenProjectCode.value).toBe('12345')
    expect(hiddenProjectUuid.value).toBe('project-uuid-123')
  })

  it('validates and submits the form when project is entered without pressing enter first', async () => {
    vi.resetModules()

    const projectInput = document.getElementById('project_cost_code_global')
    const resultDiv = document.getElementById('project_search_result')
    const form = document.querySelector('#submission_forms form')
    const hiddenProjectCode = form.querySelector('.project-cost-code-hidden')
    const hiddenProjectUuid = form.querySelector('.supplied-project-uuid-hidden')

    form.submit = vi.fn()

    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: true,
        json: vi.fn().mockResolvedValue({
          found: true,
          project: { uuid: 'project-uuid-456', name: 'Validated Project' },
        }),
      }),
    )

    await import('./choose_workflow.js')

    projectInput.value = '67890'
    form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))

    await waitForCondition(() => resultDiv.textContent === 'Project found: Validated Project')
    await waitForCondition(() => form.submit.mock.calls.length === 1)

    expect(hiddenProjectCode.value).toBe('67890')
    expect(hiddenProjectUuid.value).toBe('project-uuid-456')
  })

  it('sets project uuid hidden field to empty string when no project is found', async () => {
    vi.resetModules()

    const projectInput = document.getElementById('project_cost_code_global')
    const resultDiv = document.getElementById('project_search_result')
    const form = document.querySelector('#submission_forms form')
    const hiddenProjectCode = form.querySelector('.project-cost-code-hidden')
    const hiddenProjectUuid = form.querySelector('.supplied-project-uuid-hidden')

    vi.stubGlobal(
      'fetch',
      vi.fn().mockResolvedValue({
        ok: false,
        json: vi.fn().mockResolvedValue({
          found: false,
          error: 'Project not found',
        }),
      }),
    )

    await import('./choose_workflow.js')

    projectInput.value = '99999'
    projectInput.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }))
    await waitForCondition(() => resultDiv.textContent === 'Project not found')

    form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))

    expect(hiddenProjectCode.value).toBe('')
    expect(hiddenProjectUuid.value).toBe('')
  })

  it('shows an error and does not submit when project code is blank', async () => {
    vi.resetModules()

    const projectInput = document.getElementById('project_cost_code_global')
    const resultDiv = document.getElementById('project_search_result')
    const form = document.querySelector('#submission_forms form')

    form.submit = vi.fn()

    await import('./choose_workflow.js')

    projectInput.value = '   '
    form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }))

    expect(resultDiv.textContent).toContain('Project / Cost Code is required')
    expect(projectInput.classList.contains('is-invalid')).toBe(true)
    expect(form.submit).not.toHaveBeenCalled()
  })
})
