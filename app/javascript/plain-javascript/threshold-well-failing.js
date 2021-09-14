document.addEventListener('DOMContentLoaded', () => {

  const thresholdsHelper = document.getElementById('qc-thresholds-helper')

  if (thresholdsHelper === null) { return }

  const wells = document.getElementById('well-failures').querySelectorAll('input[type="checkbox"]')

  const skipWell = (well) => {
    well.dataset.state !=='passed' || well.dataset.disabled
  }

  thresholdsHelper
    .querySelectorAll('div[data-qc-key]')
    .forEach((div) => {
      const range = div.querySelector('input[type=range]')
      const input = div.querySelector('input[type=number]')
      const enableCheckbox = div.querySelector('input[type=checkbox]')

      const qcKey = `qc${div.dataset['qcKey']}`

      const updateThreshold = (event) => {
        threshold = parseFloat(event.target.value)
        sync()
        if (enableCheckbox.checked) { updateWells() }
      }

      const sync = () => { range.value = threshold; input.value = threshold }
      const updateWells = () => {
        wells.forEach((well) => {

          // This is the state before we load this page. We can't change state
          // on these wells, so lets escape early.
          if (skipWell(well)) { return }

          const wellValue = parseFloat(well.dataset[qcKey])
          well.checked = (wellValue < threshold)
        })
      }
      let threshold = input.value

      updateThreshold({target: input})
      range.addEventListener('input', updateThreshold)
      input.addEventListener('change', updateThreshold)
      enableCheckbox.addEventListener('change', (_) => updateThreshold({target: input}) )
    })

})
