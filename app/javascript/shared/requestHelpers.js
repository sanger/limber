import { requestsForWell } from './wellHelpers'

const requestIsActive = function(request) {
  return request.state !== 'passed' &&
    request.state !== 'cancelled' &&
    request.state !== 'failed'
}

const requestsFromPlates = function(plateObjs) {
  let requestsArray = []
  for (let p = 0; p < plateObjs.length; p++) {
    let plateObj = plateObjs[p]
    let wells = plateObj.plate.wells
    for (let w = 0; w < wells.length; w++) {
      let well = wells[w]
      let requests = requestsForWell(well)
      for (let r = 0; r < requests.length; r++) {
        // Create object for requestWithPlate
        requestsArray.push({ request: requests[r], well: well, plateObj: plateObj })
      }
    }
  }
  return requestsArray
}

export { requestIsActive, requestsFromPlates }
