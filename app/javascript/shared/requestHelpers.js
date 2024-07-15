import eventBus from '@/shared/eventBus'
import { requestsForWell } from './wellHelpers'

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
  const title = request.response.data.message[1]
  const messages = request.response.data.message[0].join(', ')
  eventBus.$emit('push-alert', {
    level: 'danger',
    title: title,
    message: messages,
  })
}

export { handleFailedRequest, requestIsActive, requestIsLibraryCreation, requestsFromPlates }
