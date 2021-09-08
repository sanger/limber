import { requestsForWell } from './wellHelpers'
// import { requestsForTube } from './tubeHelpers'

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
        requestsArray.push({ request: requests[r], well: well, plateObj: plateObj })
      }
    }
  }
  return requestsArray
}

// const requestsFromTubes = function(tubeObjs) {
//   const requestsArray = []
//   for (let p = 0; p < tubeObjs.length; p++) {
//     const tubeObj = tubeObjs[p]
//     const tube = tubeObj.tube
//     const requests = requestsForTube(tube)
//     for (let r = 0; r < requests.length; r++) {
//       requestsArray.push({ request: requests[r], tube: tube, tubeObj: tubeObj })
//     }
//   }
//   return requestsArray
// }

// export { requestIsActive, requestsFromPlates, requestsFromTubes }
export { requestIsActive, requestsFromPlates }
