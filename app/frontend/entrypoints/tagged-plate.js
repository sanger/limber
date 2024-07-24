const configElement = document.getElementById('labware-creator-config')
const tagPlatesList = JSON.parse(configElement.dataset.tagPlatesList)
const dualRequired = configElement.dataset.dualRequired === 'true'
const enforceSameTemplateWithinPool = configElement.dataset.enforceSameTemplateWithinPool === 'true'

/* global SCAPE */
// SCAPE is defined in global_message_system.js and inherited from the global namespace
// In should be refactored into a more modular design

Object.assign(SCAPE, {
  tag_plates_list: tagPlatesList,
  dualRequired: dualRequired,
  enforceSameTemplateWithinPool: enforceSameTemplateWithinPool,
})
