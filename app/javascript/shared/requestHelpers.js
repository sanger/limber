import { requestsForWell } from './wellHelpers'

const requestIsActive = function(request) {
  return request.state !== 'passed' &&
    request.state !== 'cancelled' &&
    request.state !== 'failed'
}

const requestsFromPlates = function(plateObjs) {
  let requestsArray = []
  plateObjs.forEach((plateObj) => {
    plateObj.plate.wells.forEach((well) => {
      requestsForWell(well).forEach((request) => {
          requestsArray.push({
            request: request,
            well: well,
            plateObj: plateObj
          })
      })
    })
  })
  return requestsArray
}

export { requestIsActive, requestsFromPlates }
