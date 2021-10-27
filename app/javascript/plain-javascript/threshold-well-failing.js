/**
 * Defines behaviour for failing wells based on qc thresholds.
 *
 * # Corresponding ruby
 * The `app/views/plates/_thresholds.html.erb` template is used in the well
 * failing interface and automatically renders a threshold for each attribute
 * associated with the plate, or its configuration. The presenter
 * `app/models/presenters/qc_threshold_presenter.rb` automatically determines
 * things like defaults, and maximum and minimum range values based on the values
 * associated with the wells, or in the purpose.yml configuration.
 *
 * For each attribute, we render a div with a data-qc-key tag, which identifies
 * the attribute in question (eg. molarity) and contains a range slider and
 * input both. data-qc-key is set to the attribute name, prefixed by qc, in
 * Pascal case. (eg. qcCellCount)
 *
 * #JS
 * The threshold object is considered the authoritative source of threshold
 * values. Keys are the data-qc-key value (eg. qcCellCount) with the value being
 * the scalar threshold. (eg. 50.0 for a threshold of 50nm)
 *
 * This app binds an updateThreshold event to the input action of the slider
 * and the change action of the text field. This event updates the corresponding
 * value in the threshold object, before synchronizing both fields to the same
 * value.
 *
 * Finally the app updates the status of the wells based on all thresholds.
 */
document.addEventListener('DOMContentLoaded', () => {
  // Wraps our collection of threshold helpers
  const thresholdsHelper = document.getElementById('qc-thresholds-helper')

  if (thresholdsHelper === null) { return }

  // Our wells are represented by simple checkboxes
  const wells = document.getElementById('well-failures').querySelectorAll('input[type="checkbox"]')

  // Currently we can only change the status of 'passed' wells, so skip anything else
  const skipWell = (well) => well.dataset.preventWellFail === 'true' || well.dataset.disabled

  // Wells evaluate their state based on all thresholds.
  const updateWells = () => {
    wells.forEach((well) => {
      // This is the state before we load this page. We can't change state
      // on these wells, so lets escape early.
      if (skipWell(well)) { return }

      // The well must meet all thresholds.
      const wellInvalid = Object.entries(threshold)
        .some(([qcKey, thresholdValue]) => parseFloat(well.dataset[qcKey]) < thresholdValue)

      well.checked = wellInvalid
    })
  }

  // Our authoritative store of threshold values. Updated whenever either the range or input
  // field are updated, and all fields are synchronized back to this value.
  const threshold = {}

  // Bind the appropriate threshold to each of the input fields.
  thresholdsHelper
    .querySelectorAll('div[data-qc-key]')
    .forEach((div) => {
      const range = div.querySelector('input[type=range]')
      const input = div.querySelector('input[type=number]')
      const qcKey = div.dataset['qcKey']

      const updateThreshold = (event) => {
        threshold[qcKey] = parseFloat(event.target.value)
        range.value = threshold[qcKey]
        input.value = threshold[qcKey]
        updateWells()
      }

      // Synchronize the initial values
      updateThreshold({target: input})

      // Add the bindings
      range.addEventListener('input', updateThreshold)
      input.addEventListener('change', updateThreshold)
    })

})
