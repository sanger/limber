const configElement = document.getElementById('labware-creator-config')
const tagPlatesList = JSON.parse(configElement.dataset.tagPlatesList)
const dualRequired = configElement.dataset.dualRequired === 'true'
const enforceSameTemplateWithinPool = configElement.dataset.enforceSameTemplateWithinPool === 'true'

Object.assign(SCAPE, {
  tag_plates_list: tagPlatesList,
  dualRequired: dualRequired,
  enforceSameTemplateWithinPool: enforceSameTemplateWithinPool,
})
