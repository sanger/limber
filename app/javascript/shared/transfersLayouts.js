// This files contains the logic for building transfers using different
// layouts.
//
// A resulting transfer is an object of the form:
// { request: <request object>,
//   well: <well object>,
//   plateObj: { plate: <plate object>,
//               state: <state string>,
//               index: <plate index integer>
//   },
//   targetWell: <position string>
// }

import { indexToName, nameToIndex, quadrantTargetFor } from './wellHelpers'
import buildArray from './buildArray'

const quadrantOffsets = {
  rowOffset: [0, 1, 0, 1],
  colOffset: [0, 0, 1, 1]
}


// Used to calculate QuadrantStamp transfers. Combines four plates into one.
// Receives an array of requestsWithPlates and returns an object containing an array of
// valid transfers and an array of duplicated transfers (i.e. a transfer whose
// both source and destination match a transfer already present in the
// validTransfers array will be put in the duplicatedTransfer array).
// For each request, the target well is calculated using quadrantTargetFor
// function with quadrantOffsets.
//
// Resulting plate eg. where P1-4 is Plate 1-4
// +--+--+--+--+--+--+--~
// |P1|P3|P1|P3|P1|P3|P1
// |A1|A1|A2|A2|A3|A3|A4
// +--+--+--+--+--+--+--~
// |P2|P4|P2|P4|P2|P4|P1
// |A1|A1|A2|A2|A3|A3|A4
// +--+--+--+--+--+--+--~
// |P1|P3|P1|P3|P1|P3|P1
// |B1|B1|B2|B2|B3|B3|B4
// +--+--+--+--+--+--+--~
// |P2|P4|P2|P4|P2|P4|P1
// |B1|B1|B2|B2|B3|B3|B4

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


// Creates a two dimensional matrix where each rows contains a spatial
// representation of the wells of the corresponding plate.
//
// E.g. given two 96-wells plates containing the requests for the following wells:
// Plate 1: {A1, B1, A2}  (Note: requests are not ordered)
// Plate 2: {A1, A2, B2}
//
// The matrix will look like:
// [
// [A1, B1, , , , , , , A2, ...],
// [A1, , , , , , , , A2, B2, ...]
// ]
//
// If a well contains more than one request, the extra ones will be stored in
// duplicatedRequests array.
//
// Note: Indexes are calculated for 96 wells plates only.

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

const buildTubeMatrix = function(requestsWithTubes, maxTubes) {
  console.log("*** buildTubeMatrix ***")
  const tubeMatrix = buildArray(maxTubes, () => new Array(1))
  const duplicatedRequests = []
  for (let i = 0; i < requestsWithTubes.length; i++) {
    const { request, tube, tubeObj } = requestsWithTubes[i]
    if (request === undefined) { continue }
    if (tubeMatrix[tubeObj.index][0] === undefined) {
      tubeMatrix[tubeObj.index][0] = requestsWithTubes[i]
    }
    else {
      duplicatedRequests.push(requestsWithTubes[i])
    }
  }
  return { tubeMatrix: tubeMatrix, duplicatedRequests: duplicatedRequests }
}


// Used to calculate sequential transfers.
// Receives an array of transfer requests and return an array of transfers
// where the target well is calculated from the index of the request in
// transferRequests array.
//
// Note: The target well name is calculated for a 96 well plate target.

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


const buildSequentialTubesTransfersArray = function(transferRequests) {
  const transfers = new Array(transferRequests.length)
  for (let i = 0; i < transferRequests.length; i++) {
    const requestWithTube = transferRequests[i]
    transfers[i] = {
      request: requestWithTube.request,
      tube: requestWithTube.tube,
      tubeObj: requestWithTube.tubeObj,
      targetWell: indexToName(i, 8)
    }
  }
  return transfers
}


// Used to calculate sequential transfers. Combines ten 96 well plates into one
// 96 well plate.
// Receives an array of requestsWithPlates and return an object containing
// valid transfers and duplicated transfers (i.e. a transfer whose
// both source and destination match a transfer already present in the
// validTransfers array will be put in the duplicatedTransfer array).
//
// Resulting plate Eg.
//
// Plate 1        Plate 2         Dest. Plate
// +--+--+--~     +--+--+--~      +----+----+----~
// |A1|  |A3      |A1|  |         |P1A1|P1A3|P2D2
// +--+--+--~     +--+--+--~      +----+----+----~
// |  |  |        |  |B2|B3       |P1C1|P1D3|P2B3
// +--+--+--~  +  +--+--+--~  =>  +----+----+----~
// |C1|C2|        |  |  |         |P1D1|P2A1|P2D3
// +--+--+--~     +--+--+--~      +----+----+----~
// |D1|  |D3      |  |D2|D3       |P1C2|P2B2|

const sequentialTransfers = function(requestsWithPlates) {
  console.log("*** sequentialTransfers ***")
  const { platesMatrix, duplicatedRequests } = buildPlatesMatrix(requestsWithPlates, 10, 96)
  const transferRequests = platesMatrix.flat()
  const validTransfers = buildSequentialTransfersArray(transferRequests)
  const duplicatedTransfers = buildSequentialTransfersArray(duplicatedRequests)
  return { validTransfers: validTransfers, duplicatedTransfers: duplicatedTransfers }
}



const sequentialTubeTransfers = function(requestsWithTubes) {
  console.log("*** sequentialTubeTransfers ***")
  const { tubeMatrix, duplicatedRequests } = buildTubeMatrix(requestsWithTubes, 96)
  // console.log("*** finished building tube matrix ***")
  const transferRequests = tubeMatrix.flat()
  // console.log("*** transferRequests made ***")
  const validTransfers = buildSequentialTubesTransfersArray(transferRequests)
  // console.log("*** validTransfers made ***")
const duplicatedTransfers = buildSequentialTubesTransfersArray(duplicatedRequests)
  // console.log("*** duplicatedTransfers made ***")
  return { validTransfers: validTransfers, duplicatedTransfers: duplicatedTransfers }
}

const transferFunctions = {
  quadrant: quadrantTransfers,
  sequential: sequentialTransfers,
  sequentialtube: sequentialTubeTransfers
}


// Receives an array of requestsWithLabware and a transfer layout name (either
// 'quadrant' or 'sequential' or 'sequentialtubes').
// Returns an object containing an array of valid transfers and an array of
// duplicated transfers.
// Throws an error if the transfers layout string is not mapped to a transfer
// function.

const transfersFromRequests = function(requestsWithLabware, transfersLayout) {
  console.log("*** transfersFromRequests ***")
  console.log("*** requestsWithLabware ***", requestsWithLabware)
  console.log("*** transfersLayout ***", transfersLayout)
  const transferFunction = transferFunctions[transfersLayout]
  if (transferFunction === undefined) {
    throw `Invalid transfers layout name: ${transfersLayout}`
  }
  const { validTransfers, duplicatedTransfers } = transferFunction(requestsWithLabware)
  return { valid: validTransfers, duplicated: duplicatedTransfers }
}

export { transfersFromRequests }
