import $ from 'jquery'

const configElement = document.getElementById('labware-creator-config')
const tagPlatesList = JSON.parse(configElement.dataset['tagPlatesList'])
const dualRequired = configElement.dataset['dual-required'] === 'true'
const enforceSameTemplateWithinPool = configElement.dataset['enforce-same-template-within-pool'] === 'true'

$.extend(SCAPE, {
  tag_plates_list: tagPlatesList,
  dualRequired: dualRequired,
  enforceSameTemplateWithinPool: enforceSameTemplateWithinPool,
})
