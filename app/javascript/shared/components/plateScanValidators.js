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
import { requestIsLibraryCreation, requestIsActive } from '../requestHelpers'

import _ from 'lodash'

// Returns a validator which ensures the plate is of a particular size.
// For example, to validate your typical 12*8 96 well plate: checkSize(12,8)
const checkSize = (cols, rows) => {
  return (plate) => {
    if (!plate) {
      return { valid: false, message: 'Plate not found' }
    } else if (plate.number_of_columns !== cols || plate.number_of_rows !== rows) {
      return {
        valid: false,
        message: `The plate should be ${cols}×${rows} wells in size`,
      }
    } else {
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
      if (plateList[i] && plate && plateList[i].uuid === plate.uuid) {
        occurrences++
      }
    }
    if (occurrences > 1) {
      return {
        valid: false,
        message: 'Barcode has been scanned multiple times',
      }
    } else {
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
      return {
        valid: false,
        message: 'Wells in excess: ' + excessWells.join(', '),
      }
    } else {
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
    if (!allowedStatesList.includes(plate.state)) {
      return {
        valid: false,
        message: 'Plate must have a state of: ' + allowedStatesList.join(' or '),
      }
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
    if (!qcable.lot || !qcable.lot.tag_layout_template || !qcable.lot.tag_layout_template.walking_by) {
      return {
        valid: false,
        message: 'QCable should have a tag layout template and walking by',
      }
    }
    if (!allowedWalkingByList.includes(qcable.lot.tag_layout_template.walking_by)) {
      return {
        valid: false,
        message: 'QCable layout must have a walking by of: ' + allowedWalkingByList.join(' or '),
      }
    } else {
      return validScanMessage()
    }
  }
}

// Gets a request and returns if it is an active library creation request
// Args:
//   request - request to check
// Returns:
//   Boolean indicating if is an active library creation request
const activeLibraryCreationRequest = (request) => requestIsLibraryCreation(request) && requestIsActive(request)

// Gets a well as input and return the list of requests that correspond to an active
// library creation request
// Args:
//   well - Well we want to obtain the library creation requests. The well
//          needs to have the relationship `requests_as_source`
// Returns:
//   Array of library creation requests, or empty list
const libraryCreationRequestsFromWell = (well) => well.requests_as_source.filter(activeLibraryCreationRequest)

// Gets a list of wells and returns from the only the wells that contain at least
// one active library creation requests
// Args:
//   wells - Array of wells we want to check. They need to
//           have the relationship `requests_as_source`
// Returns:
//   Array of wells that match the condition
const filterWellsWithLibraryCreationRequests = (wells) => {
  return wells.filter((well) => {
    return libraryCreationRequestsFromWell(well).length >= 1
  })
}

// Gets an integer with an integer identifying the maximum number of wells with library creation
// requests; and returns a validator method that will check if a plate has less wells containing
// library creation requests than the maximum number of wells specified.
// Args:
//   maxWellsWithRequests - Integer with the maximum number of wells with library creation
//                          requests
// Returns:
//   Validator handler, that receives as argument a plate, and returns a validation message
//   specifying if the plate is valid or not with the condition
const checkMaxCountRequests = (maxWellsWithRequests) => {
  return (plate) => {
    const numWellsWithRequest = filterWellsWithLibraryCreationRequests(plate.wells).length
    if (numWellsWithRequest > maxWellsWithRequests) {
      return {
        valid: false,
        message:
          'Plate has more than ' +
          maxWellsWithRequests +
          ' wells with submissions for library preparation (' +
          numWellsWithRequest +
          ')',
      }
    }
    return validScanMessage()
  }
}

// Gets an integer with an integer identifying the minimum number of wells with library creation
// requests; and returns a validator method that will check if a plate has more wells containing
// library creation requests than the minimum number of wells specified.
// Args:
//   maxWellsWithRequests - Integer with the minimum number of wells with library creation
//                          requests
// Returns:
//   Validator handler, that receives as argument a plate, and returns a validation message
//   specifying if the plate is valid or not with the condition
const checkMinCountRequests = (minWellsWithRequests) => {
  return (plate) => {
    const numWellsWithRequest = filterWellsWithLibraryCreationRequests(plate.wells).length
    if (numWellsWithRequest < minWellsWithRequests) {
      return {
        valid: false,
        message:
          'Plate should have at least ' +
          minWellsWithRequests +
          ' wells with submissions for library preparation (' +
          numWellsWithRequest +
          ')',
      }
    }
    return validScanMessage()
  }
}

// Gets a list of column lists specify a strings of integers (like ['1', '2', '4'], etc);
// and returns a validator method that will check if a plate has all wells containing
// library creation requests inside the columns specified.
// Args:
//   maxWellsWithRequests - Integer with the minimum number of wells with library creation
//                          requests
// Returns:
//   Validator handler, that receives as argument a plate, and returns a validation message
//   specifying if the plate is valid or not with the condition
const checkAllSamplesInColumnsList = (columnsList) => {
  return (plate) => {
    const wells = filterWellsWithLibraryCreationRequests(plate.wells)
    if (!wells.every((well) => columnsList.includes(well.position.name.slice(1)))) {
      return {
        valid: false,
        message: 'All samples should be in the columns ' + columnsList,
      }
    }
    return validScanMessage()
  }
}

// Gets the list of missing libraries for a well given the list of library types
// that it should contain.
// Args:
//   well - The well
//   libraryTypes - The list of library types the well should contain
// Returns:
//   Array of the missing library types for the well, or an empty array
const missingWellLibraries = (well, libraryTypes) => {
  const libraryCreationRequests = libraryCreationRequestsFromWell(well)
  if (libraryCreationRequests.length > 0) {
    const librariesInWell = libraryCreationRequests.map((request) => request.library_type)
    // return a list of missing libraries
    return _.difference(libraryTypes, librariesInWell)
  }
  return []
}

// Gets a list of library type names and returns a validation handler that
// can check for a plate that, if they have a list of library creation requests,
// those requests are using all the library types defined as input and this has to
// happen in every different well.
// Args:
//   library_types - Array of string with the name of the library types to check
// Returns:
//   Validation object indicating if the plate has passed the condition
const checkLibraryTypesInAllWells = (libraryTypes) => {
  return (plate) => {
    const wells = plate.wells
    for (let i = 0; i < wells.length; i++) {
      const well = wells[i]
      let missingLibraries = missingWellLibraries(well, libraryTypes)
      if (missingLibraries.length != 0) {
        return {
          valid: false,
          message: 'The well at position ' + well.position.name + ' is missing libraries: ' + missingLibraries,
        }
      }
    }
    return validScanMessage()
  }
}

// Receives a plate object and a submission state, and returns a list of submission
// ids for each well where the library request submission state matches.
// Args:
//   plate - Plate object that contains the wells, requests_as_source and submissions
//   submission_state - String with any valid submission state value ('pending', 'canceled', etc)
// Returns:
//   Array of arrays - an element for each well containing an array of integer submission ids
const getAllLibrarySubmissionsWithMatchingStateForPlate = (plate, submission_state) => {
  return filterWellsWithLibraryCreationRequests(plate.wells).map((well) => {
    return libraryCreationRequestsFromWell(well)
      .filter((request) => request.submission.state == submission_state)
      .map((request) => request.submission.id)
  })
}

// Receives a plate an returns all unique submission ids for the plate
// that are in 'ready' state
// Args:
//   plate - Plate object that contains the wells, requests_as_source and submissions
// Returns:
//   Array of integer with the list of unique submission ids
const getAllUniqueLibrarySubmissionReadyIds = (plate) => {
  return _.uniq(getAllLibrarySubmissionsWithMatchingStateForPlate(plate, 'ready').flat())
}

// Receives a plate and checks that all its wells use the same group of library submissions for
// every well.
// Args:
//   plate - Plate object that contains the wells, requests_as_source and submissions
// Returns:
//   Validation object indicating if the plate has passed the condition
const checkAllLibraryRequestsWithSameReadySubmissions = () => {
  return (plate) => {
    const [firstWellSubmissionIds, ...remainingWellsSubmissionIds] = getAllLibrarySubmissionsWithMatchingStateForPlate(
      plate,
      'ready'
    )
    // To compare lists we use _.isEqual because there is no equivalent function for lists in
    // plain Javascript
    if (
      remainingWellsSubmissionIds.every((currentElemSubmissionIds) =>
        _.isEqual(firstWellSubmissionIds.sort(), currentElemSubmissionIds.sort())
      )
    ) {
      return validScanMessage()
    } else {
      return {
        valid: false,
        message:
          'The plate has different submissions in `ready` state across its wells. All submissions should be the same for every well.',
      }
    }
  }
}

// Checks that the library submissions for the plate is the same as the list
// of submission ids passed as argument
// Args:
//   cached_submission_ids - Array of submission ids to check
// Returns:
//   Validation object indicating if the plate has passed the condition
const checkPlateWithSameReadyLibrarySubmissions = (cached_submission_ids) => {
  return (plate) => {
    if (typeof cached_submission_ids.submission_ids === 'undefined') {
      cached_submission_ids.submission_ids = getAllUniqueLibrarySubmissionReadyIds(plate)
      return validScanMessage()
    }
    if (_.isEqual(getAllUniqueLibrarySubmissionReadyIds(plate).sort(), cached_submission_ids.submission_ids.sort())) {
      return validScanMessage()
    } else {
      return {
        valid: false,
        message:
          'The submission from this plate are different from the submissions from previous scanned plates in this screen.',
      }
    }
  }
}

export {
  checkSize,
  checkDuplicates,
  checkExcess,
  checkLibraryTypesInAllWells,
  getAllLibrarySubmissionsWithMatchingStateForPlate,
  checkAllLibraryRequestsWithSameReadySubmissions,
  checkPlateWithSameReadyLibrarySubmissions,
  getAllUniqueLibrarySubmissionReadyIds,
  checkState,
  checkQCableWalkingBy,
  checkMaxCountRequests,
  checkMinCountRequests,
  checkAllSamplesInColumnsList,
}
