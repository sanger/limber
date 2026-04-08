import { disableEnterKeySubmit } from '@/javascript/lib/disable_enter_key_submit.js'

disableEnterKeySubmit('#choose_workflow_card', '#submission_forms')

const globalInput = document.getElementById('project_cost_code_global')
const resultDiv = document.getElementById('project_search_result')

if (globalInput && resultDiv) {
  let foundProjectId = null
  let validatedProjectCode = null

  const injectProjectFields = function (form, projectCode, projectUuid) {
    const hiddenProjectCode = form.querySelector('.project-cost-code-hidden')
    const hiddenProjectUuid = form.querySelector('.supplied-project-uuid-hidden')

    if (hiddenProjectCode) {
      hiddenProjectCode.value = projectCode
    }

    if (hiddenProjectUuid) {
      hiddenProjectUuid.value = projectUuid || ''
    }
  }

  const showError = function (message) {
    foundProjectId = null
    validatedProjectCode = null
    resultDiv.innerHTML = `<div class="alert alert-danger">${message}</div>`
    globalInput.classList.add('is-invalid')
  }

  const showSuccess = function (project) {
    resultDiv.textContent = `Project found: ${project.name || project.uuid}`
    globalInput.classList.remove('is-invalid')
  }

  const lookupProject = async function (projectCode) {
    resultDiv.textContent = 'Searching...'
    globalInput.classList.remove('is-invalid')

    try {
      const response = await fetch(`/plates/find_project_by_id?project_id=${encodeURIComponent(projectCode)}`)
      const data = await response.json()

      if (!response.ok || !data.found) {
        throw new Error(data.error || 'Project not found')
      }

      foundProjectId = data.project.uuid
      validatedProjectCode = projectCode
      showSuccess(data.project)
      return true
    } catch (error) {
      showError(error.message || 'Project not found')
      return false
    }
  }

  globalInput.addEventListener('input', function () {
    foundProjectId = null
    validatedProjectCode = null
    resultDiv.textContent = ''
    globalInput.classList.remove('is-invalid')
  })

  globalInput.addEventListener('keydown', async function (event) {
    if (event.key !== 'Enter') return

    event.preventDefault()
    const projectCode = globalInput.value.trim()

    if (!projectCode) {
      showError('Project / Cost Code is required')
      return
    }

    await lookupProject(projectCode)
  })

  document.querySelectorAll('#submission_forms form').forEach(function (form) {
    form.addEventListener('submit', async function (event) {
      const projectCode = globalInput.value.trim()

      if (!projectCode) {
        event.preventDefault()
        showError('Project / Cost Code is required')
        globalInput.focus()
        return
      }

      if (validatedProjectCode === projectCode && foundProjectId) {
        injectProjectFields(form, projectCode, foundProjectId)
        return
      }

      event.preventDefault()

      const projectFound = await lookupProject(projectCode)

      if (!projectFound) {
        globalInput.focus()
        return
      }

      injectProjectFields(form, projectCode, foundProjectId)
      form.submit()
    })
  })
}
