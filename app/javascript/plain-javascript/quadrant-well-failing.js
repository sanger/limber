document.addEventListener('DOMContentLoaded', () => {
  const failureTable = 'well-failures'
  const quadrantHelper = document.getElementById('quadrant-helper')

  if (quadrantHelper === null) {
    return
  }

  quadrantHelper.querySelectorAll('a[data-select-quadrant-index]').forEach((button) => {
    button.addEventListener('click', () => {
      selectQuadrant(button.dataset.selectQuadrantIndex)
    })
  })

  const selectQuadrant = (quadrantIndex) => {
    const checkboxes = document
      .getElementById(failureTable)
      .querySelectorAll(`input[data-quadrant-index="${quadrantIndex}"]`)
    checkboxes.forEach(failWell)
  }

  const failWell = (checkbox) => {
    // Failed and cancelled wells can't even be failed in bulk.
    if (checkbox.dataset.preventWellFail === 'true') {
      return
    }
    // Check the box
    checkbox.checked = true
    if (checkbox.disabled) {
      // If the box was disabled then enable it, but record that it was
      // previously disabled, as we'll need to revert this if we deselect other
      // wells in the quadrant
      checkbox.disabled = false
      checkbox.dataset.wasDisabled = true
    }
    // If we deselect a well in the quadrant, then we want to make sure revert
    // the failure of negative controls
    checkbox.addEventListener('change', restoreDisabled, { once: true })
  }

  // Re-disable any control wells which had previously been enabled
  const restoreDisabled = (event) => {
    const quadrantIndex = event.target.dataset.quadrantIndex
    const checkboxes = document
      .getElementById(failureTable)
      .querySelectorAll(`input[data-quadrant-index="${quadrantIndex}"][data-was-disabled="true"]`)
    checkboxes.forEach((boxToDisable) => {
      boxToDisable.disabled = true
      boxToDisable.checked = false // Not strictly necessary, but otherwise the well
      // remains red
    })
  }
})
