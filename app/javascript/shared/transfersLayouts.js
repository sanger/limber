import { indexToName, nameToIndex, quadrantTargetFor } from './wellHelpers'
import buildArray from './buildArray'


const quadrantOffsets = {
  rowOffset: [0,1,0,1],
  colOffset: [0,0,1,1]
}

const quadrantTransfers = function(requestsWithPlates) {
  const transfersSet = new Set()
  const validTransfers = []
  const duplicatedTransfers = []
  for (let i = 0; i < requestsWithPlates.length; i++) {
    const { request, well, plateObj } = requestsWithPlates[i]
    if (request === undefined) { continue }
    const targetWell = quadrantTargetFor(
      plateObj.index,
      well.position.name,
      quadrantOffsets.rowOffset,
      quadrantOffsets.colOffset
    )
    const transfer = {
      request: request,
      well: well,
      plateObj: plateObj,
      targetWell: targetWell
    }
    const transferStr = well.position.name + targetWell
    if (transfersSet.has(transferStr)) {
      duplicatedTransfers.push(transfer)
    }
    else {
      transfersSet.add(transferStr)
      validTransfers.push(transfer)
    }
  }
  return { validTransfers: validTransfers, duplicatedTransfers: duplicatedTransfers }
}

const buildPlatesMatrix = function(requestsWithPlates, maxPlates, maxWellsPerPlate) {
  const platesMatrix = buildArray(maxPlates, () => new Array(maxWellsPerPlate))
  const duplicatedRequests = []
  for (let i = 0; i < requestsWithPlates.length; i++) {
    const { request, well, plateObj } = requestsWithPlates[i]
    if (request === undefined) { continue }
    const wellIndex = nameToIndex(well.position.name, 8)
    if (platesMatrix[plateObj.index][wellIndex] === undefined) {
      platesMatrix[plateObj.index][wellIndex] = requestsWithPlates[i]
    }
    else {
      duplicatedRequests.push(requestsWithPlates[i])
    }
  }
  return { platesMatrix: platesMatrix, duplicatedRequests: duplicatedRequests }
}

const buildSequentialTransfersArray = function(transferRequests) {
  const transfers = new Array(transferRequests.length)
  for (let i = 0; i < transferRequests.length; i++) {
    const requestWithPlate = transferRequests[i]
    transfers[i] = {
      request: requestWithPlate.request,
      well: requestWithPlate.well,
      plateObj: requestWithPlate.plateObj,
      targetWell: indexToName(i, 8)
    }
  }
  return transfers
}

const sequentialTransfers = function(requestsWithPlates) {
  const { platesMatrix, duplicatedRequests } = buildPlatesMatrix(requestsWithPlates, 10, 96)
  const transferRequests = platesMatrix.flat()
  const validTransfers = buildSequentialTransfersArray(transferRequests)
  const duplicatedTransfers = buildSequentialTransfersArray(duplicatedRequests)
  return { validTransfers: validTransfers, duplicatedTransfers: duplicatedTransfers }
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
  const { validTransfers, duplicatedTransfers } = transferFunction(requestsWithPlates)
  return { valid: validTransfers, duplicated: duplicatedTransfers }
}

export { transfersFromRequests }
