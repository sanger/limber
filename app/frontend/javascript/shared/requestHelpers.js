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
  // Errors seem to have different formats, this is an attempt to handle several types
  const title = request.response?.data?.message?.[1] || request.response?.statusText || 'Error'
  const messages = request.response?.data?.message
    ? Array.isArray(request.response.data.message)
      ? request.response.data.message.join(', ')
      : request.response.data.message
    : request.message || 'Cannot determine error message'

  eventBus.$emit('push-alert', {
    level: 'danger',
    title: title,
    message: messages,
  })
}

export { handleFailedRequest, requestIsActive, requestIsLibraryCreation, requestsFromPlates }
