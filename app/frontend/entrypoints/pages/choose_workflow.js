import { disableEnterKeySubmit } from '@/javascript/lib/disable_enter_key_submit.js'

disableEnterKeySubmit('#choose_workflow_card', '#submission_forms')

const globalInput = document.getElementById('project_cost_code_global')
const resultDiv = document.getElementById('project_search_result')

if (globalInput && resultDiv) {
	let foundProjectId = null

	globalInput.addEventListener('keydown', function (event) {
		if (event.key !== 'Enter') return

		event.preventDefault()
		const projectId = globalInput.value.trim()
		if (!projectId) return

		resultDiv.textContent = 'Searching...'

		fetch(`/plates/find_project_by_id?project_id=${encodeURIComponent(projectId)}`)
			.then((response) => response.json())
			.then((data) => {
				if (data.found) {
					foundProjectId = data.project.uuid
					resultDiv.textContent = `Project found: ${data.project.name || data.project.uuid}`
					return
				}

				foundProjectId = null
				resultDiv.textContent = data.error || 'Project not found.'
			})
			.catch(() => {
				foundProjectId = null
				resultDiv.textContent = 'Error searching for project.'
			})
	})

	document.querySelectorAll('#submission_forms form').forEach(function (form) {
		form.addEventListener('submit', function () {
			const hiddenProjectCode = form.querySelector('.project-cost-code-hidden')
			const hiddenProjectUuid = form.querySelector('.supplied-project-uuid-hidden')

			if (hiddenProjectCode) {
				hiddenProjectCode.value = globalInput.value
			}

			if (hiddenProjectUuid) {
				hiddenProjectUuid.value = foundProjectId || ''
			}
		})
	})
}
