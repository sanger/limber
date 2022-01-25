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

const buildLibrarySplitPlatesMatrix = function(requestsWithPlates) {
  //const platesMatrix = buildArray(maxPlates, () => new Array(maxWellsPerPlate))
  const platesMatrix = []
  const duplicatedRequests = []
  for (let i = 0; i < requestsWithPlates.length; i++) {
    const { request, well, plateObj } = requestsWithPlates[i]
    if (request === undefined) { continue }
    const wellIndex = nameToIndex(well.position.name, 8)
    if (platesMatrix[plateObj.index] === undefined) {
      platesMatrix[plateObj.index] = {}
    }
    if (platesMatrix[plateObj.index][request.library_type] === undefined) {
      platesMatrix[plateObj.index][request.library_type] = []
    }
    if (platesMatrix[plateObj.index][request.library_type][wellIndex] === undefined) {
      platesMatrix[plateObj.index][request.library_type][wellIndex] = requestsWithPlates[i]
    }
    else {
      duplicatedRequests.push(requestsWithPlates[i])
    }
  }
  return { platesMatrix: platesMatrix, duplicatedRequests: duplicatedRequests }
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

// TODO: targetWell should go to the specific column for the plate (plate 1: [1,2,3], plate2: [4,5,6])
const buildSequentialLibrarySplitTransfersArray = function(transferRequests) {
  const transfers = new Array(transferRequests.length)
  const libraryTypes = []
  const positionWellInLibraryTypePlate = {}
  for (let i = 0; i < transferRequests.length; i++) {
    const requestWithPlate = transferRequests[i]
    var libraryType = requestWithPlate.request.library_type
    
    if (libraryTypes.indexOf(libraryType) < 0) {
      libraryTypes[libraryTypes.length] = libraryType
      positionWellInLibraryTypePlate[libraryType] = 0
    }

    const positionWell = positionWellInLibraryTypePlate[libraryType]
    const positionPlate = libraryTypes.indexOf(libraryType)

    transfers[i] = {
      request: requestWithPlate.request,
      well: requestWithPlate.well,
      plateObj: requestWithPlate.plateObj,
      targetWell: indexToName(positionWell, 8),
      targetPlate: positionPlate
    }
    positionWellInLibraryTypePlate[libraryType] += 1
  }
  return transfers
}


// Takes an array with 96 elements (for a 96 well plate)
// Returns an array with elements just for those wells that have been populated (by scanning into the UI)
// including the target well coordinate.
// Example of one element of the output array:
// {
//   targetWell: "A1",
//   tubeObj:
//   {
//     index: 0,
//     tube:
//     {
//       id: "1",
//       labware_barcode:
//       {
//         human_barcode: "NT4R",
//         ...
//       },
//       links: {self: "http://localhost:3000/api/v2/tubes/9"},
//       receptacle:
//       {
//         type: "tubes",
//         uuid: "db4f1e22-1230-11ec-962c-38f9d3dee0d3"
//       }
//     }
//   }
// }
const buildSequentialTubesTransfersArray = function(transferRequests) {
  const transfers = new Array()

  for (let i = 0; i < transferRequests.length; i++) {
    if(transferRequests[i] === undefined){
      continue
    }

    const tubeTransferReq = transferRequests[i]
    transfers.push( {
      tubeObj: { tube: tubeTransferReq.labware, index: tubeTransferReq.index },
      targetWell: indexToName(i, 8)
    })
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
  const { platesMatrix, duplicatedRequests } = buildPlatesMatrix(requestsWithPlates, 10, 96)
  const transferRequests = platesMatrix.flat()
  const validTransfers = buildSequentialTransfersArray(transferRequests)
  const duplicatedTransfers = buildSequentialTransfersArray(duplicatedRequests)
  return { validTransfers: validTransfers, duplicatedTransfers: duplicatedTransfers }
}


const sequentialLibrarySplitTransfers = function(requestsWithPlates) {
  const { platesMatrix, duplicatedRequests } = buildLibrarySplitPlatesMatrix(requestsWithPlates)
  const transferRequests = platesMatrix.flatMap((x) => Object.values(x)).flat()
  const validTransfers = buildSequentialLibrarySplitTransfersArray(transferRequests)
  const duplicatedTransfers = buildSequentialLibrarySplitTransfersArray(duplicatedRequests)
  return { validTransfers: validTransfers, duplicatedTransfers: duplicatedTransfers }
}

const transferFunctions = {
  quadrant: quadrantTransfers,
  sequential: sequentialTransfers,
  sequentialLibrarySplit: sequentialLibrarySplitTransfers,
}


// Receives an array of requestsWithPlates and a transfer layout name (either
// 'quadrant' or 'sequential').
// Returns an object containing an array of valid transfers and an array of
// duplicated transfers.
// Throws an error if the transfers layout string is not mapped to a transfer
// function.

const transfersFromRequests = function(requestsWithPlates, transfersLayout) {
  const transferFunction = transferFunctions[transfersLayout]
  if (transferFunction === undefined) {
    throw `Invalid transfers layout name: ${transfersLayout}`
  }
  const { validTransfers, duplicatedTransfers } = transferFunction(requestsWithPlates)
  return { valid: validTransfers, duplicated: duplicatedTransfers }
}


// Receives an array of potential transfers and a transfer layout name
// (valid options: 'sequentialtubes').
// Returns an object containing an array of valid transfers
// Throws an error if the transfers layout string is not mapped to a transfer
// function.
// Inputs:
//      validTubes: [
//        { index: 0, state: 'valid', tube: {} },
//        { index: 1, state: 'valid', tube: {} },
//        ...etc...
//      ]
//
const transfersForTubes = function(validTubes) {
  const maxTubes = 96
  const tubeArray = new Array(maxTubes)

  for (let i = 0; i < validTubes.length; i++) {
    const tubeObj = validTubes[i]
    if (tubeArray[tubeObj.index] === undefined) {
      tubeArray[tubeObj.index] = validTubes[i]
    }
  }

  const validTransfers = buildSequentialTubesTransfersArray(tubeArray)
  const duplicatedTransfers = []
  return { valid: validTransfers, duplicated: duplicatedTransfers }
}

export { transfersFromRequests, transfersForTubes, buildPlatesMatrix, buildLibrarySplitPlatesMatrix }
