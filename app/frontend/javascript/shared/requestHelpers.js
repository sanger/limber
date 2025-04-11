import eventBus from '@/javascript/shared/eventBus.js'
import { requestsForWell } from './wellHelpers.js'

const requestIsActive = function (request) {
  return request.state !== 'passed' && request.state !== 'cancelled' && request.state !== 'failed'
}

const requestIsLibraryCreation = function (request) {
  return request.library_type != null
}

const requestsFromPlates = function (plateObjs) {
  const requestsArray = []
  for (let p = 0; p < plateObjs.length; p++) {
    const plateObj = plateObjs[p]
    const wells = plateObj.plate.wells
    for (let w = 0; w < wells.length; w++) {
      const well = wells[w]
      const requests = requestsForWell(well)
      for (let r = 0; r < requests.length; r++) {
        requestsArray.push({
          request: requests[r],
          well: well,
          plateObj: plateObj,
        })
      }
    }
  }
  return requestsArray
}

const handleFailedRequest = function (request) {
  // generate an alert on the page
  let title = 'Unexpected error'
  let messages = 'Cannot determine error messages'

  // Errors seem to have different formats, this is an attempt to handle several types
  if (Array.isArray(request.response?.data?.message) && request.response.data.message.length > 1) {
    title = request.response.data.message[1]
    messages = request.response.data.message[0].join(', ')
  } else if (request.response?.statusText != null) {
    title = request.response?.statusText
    messages = request.response?.data?.message || request.message || 'Cannot parse messages'
  }

  eventBus.$emit('push-alert', {
    level: 'danger',
    title: title,
    message: messages,
  })
}

export { handleFailedRequest, requestIsActive, requestIsLibraryCreation, requestsFromPlates }
