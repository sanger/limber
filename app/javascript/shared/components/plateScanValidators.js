// Plate Scan Validators can be passed in to a LabwareScan.vue component to
// provide custom validation.
//
// A validator is a function which:
// 1) Takes the result of the APi query (usually a plate) as a sole argument
// 2) Returns javascript object with two properties:
//    a) valid: A Boolean indicating if the plate is suitable or not
//    b) message: A string which will be displayed to the user. Especially
//                important for failures.
//
// Dynamic validation
// In many case you may want to validate a plate against a dynamic set of
// criteria, or to provide some customization options. In these cases you can
// wrap your validator in an external function, which takes the configuration
// options as parameters. These parameters will be available to the validator
// function itself.
//
// For example:
// const myValidator(option) => {
//  // This function gets called when the validator is set up. If part of a
//  // computed function a new // validator will be generated each time option
//  // changes. This will allow validation to respond // dynamically to changes
//  // elsewhere on the page.
//  // Typically you only NEED to return the validator function here
//  return (plate) => {
//    // This is the validator itself. It has access to option, and any other
//    // parameters defined above
//    // In this example, we ensure that the plate thing is option
//    if (plate.thing == option) {
//       return { valid: true, message: 'The plate is suitable' }
//     } else {
//       return { valid: false, message: 'The plate thing should be option' }
//     }
//  }
//}
//
// Validating multiple criteria
// Try and keep validators checking one thing only. It makes them easier to
// test and reuse. Multiple validators can be combined together using the aggregate
// function in scanValidators.js

import { validScanMessage } from './scanValidators'
import _ from 'lodash'

// Returns a validator which ensures the plate is of a particular size.
// For example, to validate your typical 12*8 96 well plate: checkSize(12,8)
const checkSize = (cols, rows) => {
  return (plate) => {
    if (!plate) {
      return { valid: false, message: 'Plate not found' }
    }
    else if (plate.number_of_columns !== cols || plate.number_of_rows !== rows) {
      return { valid: false, message: `The plate should be ${cols}×${rows} wells in size` }
    }
    else {
      return validScanMessage()
    }
  }
}

// Returns a validator that ensures that the scanned item does not appear
// multiple times in the list (based on UUID).
// plateList: An array of plates that have already been scanned. Can include
//            null to represent empty plate
const checkDuplicates = (plateList) => {
  return (plate) => {
    let occurrences = 0
    for (let i = 0; i < plateList.length; i++) {
      if (plateList[i] && plate && plateList[i].uuid === plate.uuid) { occurrences++ }
    }
    if (occurrences > 1) {
      return { valid: false, message: 'Barcode has been scanned multiple times' }
    }
    else {
      return validScanMessage()
    }
  }
}

// Returns a validator that checks if there are wells in the scanned plate that
// are in excess (i.e. the sum of valid transfers across scanned
// plates is greater than the number of wells in the target plate).
// It also returns the excess wells' position.
// excessTransfers: An array of transfers that cannot be included in the
//                     target plate as all the wells are already occupied.
const checkExcess = (excessTransfers) => {
  return (plate) => {
    const excessWells = []
    for (let i = 0; i < excessTransfers.length; i++) {
      if (plate && excessTransfers[i].plateObj.plate.uuid === plate.uuid) {
        excessWells.push(excessTransfers[i].well.position.name)
      }
    }
    if (excessWells.length > 0) {
      return { valid: false, message: 'Wells in excess: ' + excessWells.join(', ') }
    }
    else {
      return validScanMessage()
    }
  }
}

// Returns a validator that ensures the plate has a state that matches to the
// supplied list of states. e.g. to check a plate has a state of 'available'
// or 'exhausted':
// checkState(['available', 'exhausted'])
const checkState = (allowedStatesList) => {
  return (plate) => {
    if(!allowedStatesList.includes(plate.state)) {
      return { valid: false, message: 'Plate must have a state of: ' + allowedStatesList.join(' or ') }
    } else {
      return validScanMessage()
    }
  }
}

// Returns a validator that ensures the QCable tag plate has a walking by that
// matches the supplied walking by list. e.g. to check a QCable has a walking
// by of 'wells of plate':
// checkQCableWalkingBy(['wells of plate'])
const checkQCableWalkingBy = (allowedWalkingByList) => {
  return (qcable) => {
    if(!qcable.lot || !qcable.lot.tag_layout_template || !qcable.lot.tag_layout_template.walking_by) {
      return { valid: false, message: 'QCable should have a tag layout template and walking by' }
    }
    if(!allowedWalkingByList.includes(qcable.lot.tag_layout_template.walking_by)) {
      return { valid: false, message: 'QCable layout must have a walking by of: ' + allowedWalkingByList.join(' or ') }
    } else {
      return validScanMessage()
    }
  }
}

const requestsFromWell = (well) => {
  return well.requests_as_source.length
}

const filterWellsWithRequest = (wells) => {
  return wells.filter((well) => { return (requestsFromWell(well) >= 1) })
}

const checkMaxCountRequests = (maxWellsWithRequests) => {
  return (plate) => {
    const numWellsWithRequest = filterWellsWithRequest(plate.wells).length
    if (numWellsWithRequest > maxWellsWithRequests) {
      return { valid: false, message: 'Plate has more than '+maxWellsWithRequests+' wells with submissions for library preparation ('+numWellsWithRequest+')' }
    }
    return validScanMessage()
  }
}

const checkMinCountRequests = (minWellsWithRequests) => {
  return (plate) => {
    const numWellsWithRequest = filterWellsWithRequest(plate.wells).length
    if (numWellsWithRequest < minWellsWithRequests) {
      return { valid: false, message: 'Plate should have at least '+minWellsWithRequests+' wells with submissions for library preparation ('+numWellsWithRequest+')' }
    }
    return validScanMessage()
  }
}

const checkAllSamplesInColumnsList = (columnsList) => {
  return (plate) => {
    const wells = filterWellsWithRequest(plate.wells)
    for (var i=0; i<wells.length; i++) {
      var well = wells[i]
      var column = well.position.name.slice(1)
      if (!columnsList.includes(column)) {
        return { valid: false, message: 'All samples should be in the columns '+columnsList }
      }
    }
    return validScanMessage()
  }
}

const substractArrays = (array_a, array_b) => {
  return array_a.filter(n => !array_b.includes(n))
}

const checkLibraryTypesInAllWells = (libraryTypes) => {
  return (plate) => {
    for (var posWell=0; posWell<plate.wells.length; posWell++) {
      var well = plate.wells[posWell]
      const wellPosition = well.position.name
      // Only wells with requests are checked
      if (well.requests_as_source.length > 0) {
        const librariesInWell = well.requests_as_source.map((request) => request.library_type)
        const libraryTypesSubstraction = substractArrays(libraryTypes, librariesInWell)
        if (libraryTypesSubstraction.length != 0) {
          return { valid: false, 
            message: 'The well at position '+wellPosition+' is missing libraries: '+libraryTypesSubstraction 
          }
        }
      }
    }
    return validScanMessage()
  }
}

const getAllSubmissionsWithStateForPlate = (plate, submission_state) => {
  return plate.wells.filter((well) => well.requests_as_source.length > 0 ).map((well) => {
    return well.requests_as_source.filter(
      (request) => request.submission.state == submission_state
    ).map((request) => request.submission.id)
  })
}

const getAllUniqueSubmissionReadyIds = (plate) => {
  return _.uniq(getAllSubmissionsWithStateForPlate(plate, 'ready').flat())
}

const checkAllRequestsWithSameReadySubmissions = () => {
  return (plate) => {
    const allSubmissions = getAllSubmissionsWithStateForPlate(plate, 'ready')
    const firstElem = allSubmissions[0]
    // To compare lists we use _.isEqual because there is no equivalent function for lists in 
    // plain Javascript
    if (allSubmissions.every((currentElem) => _.isEqual(firstElem, currentElem))) {
      return validScanMessage()
    } else {
      return { valid: false, 
        message: 'The plate has different submissions in `ready` state across its wells. All submissions should be the same for every well.'
      }    
    }
  }
}

const checkPlateWithSameReadySubmissions = (cached_submission_ids) => {
  return (plate) => {
    if (typeof cached_submission_ids.submission_ids === 'undefined') {
      cached_submission_ids.submission_ids = getAllUniqueSubmissionReadyIds(plate)
      return validScanMessage()
    }
    if (_.isEqual(getAllUniqueSubmissionReadyIds(plate), cached_submission_ids.submission_ids)) {
      return validScanMessage()
    } else {
      return { valid: false, 
        message: 'The submission from this plate are different from the submissions from previous scanned plates in this screen.'
      }
    }
  }
}

export { checkSize, checkDuplicates, checkExcess, 
  checkLibraryTypesInAllWells, substractArrays, 
  getAllSubmissionsWithStateForPlate,
  checkAllRequestsWithSameReadySubmissions,
  checkPlateWithSameReadySubmissions,
  getAllUniqueSubmissionReadyIds,
  checkState, checkQCableWalkingBy, checkMaxCountRequests, checkMinCountRequests, checkAllSamplesInColumnsList
}
