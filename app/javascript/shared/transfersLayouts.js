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

import { requestIsLibraryCreation, requestIsActive } from './requestHelpers'
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

// Creates an object with an array of three dimensions, grouping the requests by source plate, library
// type and well index.
//
// E.g. given two 96-wells plates containing the requests for the following wells:
// Plate 1: {P1-A1-Lib1, P1-A1-Lib2, P1-B1-Lib1, P1-A2-Lib1}  (Note: requests are not ordered)
// Plate 2: {P2-A1-Lib1, P2-A2-Lib1, P2-A2-Lib1, P2-B2-Lib1}
// Being transferred into two destination plates
//
// The resulting object will look like this:
// {
//   'Plate1': {
//     {'Lib1': {'A1': P1-A1-Lib1,'B1': P1-B1-Lib1, 'A2': P1-A2-Lib1]},
//     {'Lib2': {'A1': P1-A1-Lib1}}
//   },
//   'Plate2': {
//      {'Lib1': {'A1': P2-A1-Lib1, 'A2': P2-A2-Lib1, 'B2': P2-B2-Lib1]}
//    }
// }
// If a well contains more than one copy of the same library request, the extra ones will be stored in
// a duplicatedRequests array:
// [P2-A2-Lib1]
//
const buildLibrarySplitPlatesMatrix = function(requestsWithPlates) {
  const platesMatrix = []
  const duplicatedRequests = []

  for (const requestObj of requestsWithPlates) {
    const { request, well, plateObj } = requestObj
    if (request === undefined) { continue }
    const wellIndex = nameToIndex(well.position.name, 8)
    platesMatrix[plateObj.index] ??= {}
    platesMatrix[plateObj.index][request.library_type] ??= []
    if (typeof platesMatrix[plateObj.index][request.library_type][wellIndex] === 'undefined') {
      // We classify requests by source plate, library type and well position at source
      platesMatrix[plateObj.index][request.library_type][wellIndex] = requestObj
    }
    else {
      // All extra requests in the same source plate, library type and position
      // go to the duplication list
      duplicatedRequests.push(requestObj)
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

// Gets a list of requests and create as many destinations as different library types we have defined in the requests.
// For every source plate a number of wells at the destination is assigned so the wells will be transferred as stamp into
// those list of wells reserved in column order. Eg:
// Default value is 24 wells, so first plate will get the first 3 columns, second plate columns 4 to 6, etc; the position
// will be a stamp from the source into those columns (so A2 in plate 2 will go to A5 in each destination plate)
// Args:
// - transferRequests: each request from a source plate that we want to connect with a destination plate
// - numberOfWellsForEachSourcePlateInColumnOrder: number of wells that every source plate will have reserved in each
// destination plate (default 24 wells (3 columns))
//
const buildSequentialLibrarySplitTransfersArray = function(transferRequests, numberOfWellsForEachSourcePlateInColumnOrder=24) {
  const libraryTypes = []
  return transferRequests.map((requestWithPlate) => {
    const libraryType = requestWithPlate.request.library_type

    if (!libraryTypes.includes(libraryType)) {
      libraryTypes.push(libraryType)
    }

    const incrementalWellsForPlate = requestWithPlate.plateObj.index * numberOfWellsForEachSourcePlateInColumnOrder
    const wellIndex = nameToIndex(requestWithPlate.well.position.name, 8) + incrementalWellsForPlate
    const plateIndex = libraryTypes.indexOf(libraryType)
    return {
      request: requestWithPlate.request,
      well: requestWithPlate.well,
      plateObj: requestWithPlate.plateObj,
      targetWell: indexToName(wellIndex, 8),
      targetPlate: plateIndex
    }
  })
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

// Returns only the active library creation requests from a list of requests as input
// Args:
//   requestsWithPlates - Array of requests
// Returns:
//   Array of active library creation requests
const libraryRequestsWithPlates = function(requestsWithPlates) {
  return requestsWithPlates.filter((obj) => requestIsLibraryCreation(obj.request) && requestIsActive(obj.request))
}

// TransferFunction that defines the creation of as many destination plates as library types have been defined
// in the library creation requests at the input plates.
// The number of input plates that are going to be transferred is limited to 4.
// From each input plate it will pick up the first 3 columns (24 wells, wells A1 to H3).
// These columns will be stamped into successive sets of 3 columns on the destination plate(s),
// source 1 to columns 1-3, source 2 to columns 4-6, source 3 to columns 7-9, and source 4 to columns 10-12.
// Returns an object with the list of valid transfers and a list of duplicates, where a duplicate is a request
// from same source plate, same library type and same well at input.
// Args:
//   requestsWithPlates - Array of requests from the input plates
// Returns:
//   Object with key 'validTransfers' with the list of requests that are not duplicates, and 'duplicatedTransfers'
//   with the duplicated requests
const stampLibrarySplitTransfers = function(requestsWithPlates) {
  const filteredOnlyLibraryRequestsWithPlates = libraryRequestsWithPlates(requestsWithPlates)
  const { platesMatrix, duplicatedRequests } = buildLibrarySplitPlatesMatrix(filteredOnlyLibraryRequestsWithPlates)
  const transferRequests = platesMatrix.flatMap((x) => Object.values(x)).flat()
  const validTransfers = buildSequentialLibrarySplitTransfersArray(transferRequests, 24)
  const duplicatedTransfers = buildSequentialLibrarySplitTransfersArray(duplicatedRequests, 24)
  return { validTransfers, duplicatedTransfers }
}

// Mapping of allowed transfer functions
const transferFunctions = {
  quadrant: quadrantTransfers,
  sequential: sequentialTransfers,
  sequentialLibrarySplit: stampLibrarySplitTransfers,
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

export { transfersFromRequests, transfersForTubes, buildPlatesMatrix, buildLibrarySplitPlatesMatrix, buildSequentialLibrarySplitTransfersArray }
