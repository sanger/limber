import { indexToName, nameToIndex, quadrantTargetFor } from './wellHelpers'
import buildArray from './buildArray'


const quadrantOffsets = {
  rowOffset: [0,1,0,1],
  colOffset: [0,0,1,1]
}

const quadrantTransfers = function(requestsWithPlates) {
  let transfers = []
  for (let i = 0; i < requestsWithPlates.length; i++) {
    let { request, well, plateObj } = requestsWithPlates[i]
    if (request === undefined) { continue }
    let targetWell = quadrantTargetFor(
      plateObj.index,
      well.position.name,
      quadrantOffsets.rowOffset,
      quadrantOffsets.colOffset
    )
    // Create an object for this (it adds targetWell)
    transfers.push({
      request: request,
      well: well,
      plateObj: plateObj,
      targetWell: targetWell
    })
  }
  return transfers
}

const buildPlatesMatrix = function(requestsWithPlates, maxPlates, maxWellsPerPlate) {
  let platesMatrix = buildArray(maxPlates, () => new Array(maxWellsPerPlate))
  for (let i = 0; i < requestsWithPlates.length; i++) {
    let { request, well, plateObj } = requestsWithPlates[i]
    if (request === undefined) { continue }
    platesMatrix[plateObj.index][nameToIndex(well.position.name, 8)] = requestsWithPlates[i]
  }
  return platesMatrix
}

const sequentialTransfers = function(requestsWithPlates) {
  const transferRequests = buildPlatesMatrix(requestsWithPlates, 10, 96).flat()
  let transfers = new Array(transferRequests.length)
  for (let i = 0; i < transfers.length; i++) {
    let requestWithPlate = transferRequests[i]
    transfers[i] = {
      request: requestWithPlate.request,
      well: requestWithPlate.well,
      plateObj: requestWithPlate.plateObj,
      targetWell: indexToName(i, 8)
    }
  }
  return transfers
}

const transferFunctions = {
  quadrant: quadrantTransfers,
  sequential: sequentialTransfers
}

const transfersFromRequests = function(requestsWithPlates, transfersLayout) {
  const transferFunction = transferFunctions[transfersLayout]
  if (transferFunction === undefined) {
    throw `Invalid transfers layout name: ${transfersLayout}`
  }
  const transfers = transferFunction(requestsWithPlates)
  let transfersArray = new Array(transfers.length)
  for (let i = 0; i < transfersArray.length; i++) {
    let transfer = transfers[i]
    transfersArray[i] = {
      source_plate: transfer.plateObj.plate.uuid,
      pool_index: transfer.plateObj.index + 1,
      source_asset: transfer.well.uuid,
      outer_request: transfer.request.uuid,
      new_target: { location: transfer.targetWell }
    }
  }
  return transfersArray
}

export { transfersFromRequests }
