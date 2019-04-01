import { requestsForWell } from './wellHelpers'

const requestIsActive = function(request) {
  return request.state !== 'passed' &&
    request.state !== 'cancelled' &&
    request.state !== 'failed'
}

const requestsFromPlates = function(plateObjs) {
  const requestsArray = []
  for (let p = 0; p < plateObjs.length; p++) {
    const plateObj = plateObjs[p]
    const wells = plateObj.plate.wells
    for (let w = 0; w < wells.length; w++) {
      const well = wells[w]
      const requests = requestsForWell(well)
      for (let r = 0; r < requests.length; r++) {
        // TODO: Create object for requestWithPlate
        requestsArray.push({ request: requests[r], well: well, plateObj: plateObj })
      }
    }
  }
  return requestsArray
}

export { requestIsActive, requestsFromPlates }
