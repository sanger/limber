// Tube Scan Validators can be passed in to a LabwareScan.vue component to
// provide custom validation.
//
// A validator is a function which:
// 1) Takes the result of the API query (usually a tube) as a sole argument
// 2) Returns javascript object with two properties:
//    a) valid: A Boolean indicating if the tube is suitable or not
//    b) message: A string which will be displayed to the user. Especially
//                important for failures.
//
// Dynamic validation
// In many case you may want to validate a tube against a dynamic set of
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
//  return (tube) => {
//    // This is the validator itself. It has access to option, and any other
//    // parameters defined above
//    // In this example, we ensure that the tube thing is option
//    if (tube.thing == option) {
//       return { valid: true, message: 'The tube is suitable' }
//     } else {
//       return { valid: false, message: 'The tube thing should be option' }
//     }
//  }
//}
//
// Validating multiple criteria
// Try and keep validators checking one thing only. It makes them easier to test
// and reuse. Multiple validators can be combined together using the aggregate
// function in scanValidators.js

import { validScanMessage } from './scanValidators.js'
import { purposeConfigForTube } from '@/javascript/shared/tubeHelpers.js'
import {
  purposeTargetMolarityParameter,
  purposeTargetVolumeParameter,
  purposeMinimumPickParameter,
  tubeMostRecentMolarity,
} from '@/javascript/shared/tubeTransferVolumes'

// Returns a validator that ensures that the scanned item does not appear
// multiple times in the list (based on UUID).
// tubeList: An array of tubes that have already been scanned. Can include
//           null to represent empty tube
const checkDuplicates = (tubeList) => {
  return (tube) => {
    let occurrences = 0
    for (let i = 0; i < tubeList.length; i++) {
      if (tubeList[i] && tube && tubeList[i].uuid === tube.uuid) {
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

// Returns a validator that ensures the tube has an ID in the allowed list.
// To allow tubes with IDs in the list 123, 345, 567 and an invalid message:
// checkId(['123', '345', '567'], 'Invalid ID')
const checkId = (allowedIds, invalidMessage) => {
  return (tube) => {
    if (!allowedIds.includes(tube?.id)) {
      return { valid: false, message: invalidMessage }
    } else {
      return validScanMessage()
    }
  }
}

// Returns a validator that ensures the purpose names of all the tubes match
// the name for the one provided. Typically the one provided should be the one
// of the purposes from the full set of tubes being validated.
const checkMatchingPurposes = (purpose) => {
  return (tube) => {
    if (tube && purpose && tube.purpose?.name !== purpose.name) {
      return {
        valid: false,
        message: `Tube purpose '${tube.purpose?.name || 'UNKNOWN'}' doesn't match other tubes`,
      }
    }

    return validScanMessage()
  }
}

// Returns a validator that ensures the tube contains at least one QC result
// for molarity in nM.
const checkMolarityResult = () => {
  return (tube) => {
    if (tubeMostRecentMolarity(tube) === undefined) {
      return { valid: false, message: 'Tube has no molarity QC result' }
    } else {
      return validScanMessage()
    }
  }
}

// Returns a validator that ensures the tube has a state that matches the
// supplied list of states. e.g. to check a tube has a state of 'available'
// or 'exhausted':  checkState(['available', 'exhausted'])
const checkState = (allowedStatesList) => {
  return (tube) => {
    if (!allowedStatesList.includes(tube.state)) {
      return {
        valid: false,
        message: `Tube (state: ${tube.state}) must have a state of: ${allowedStatesList.join(' or ')}`,
      }
    } else {
      return validScanMessage()
    }
  }
}

// Returns a validator that ensures the scanned tube has a purpose with configured
// transfer parameters.  All three parameters are needed to perform a transfer volume
// calculation.
// purposeConfigs: An object containing keys for purpose UUIDs, and values containing
//                 the config options for each purpose.
const checkTransferParameters = (purposeConfigs) => {
  return (tube) => {
    const purposeConfig = purposeConfigForTube(tube, purposeConfigs)
    const targetMolarity = purposeTargetMolarityParameter(purposeConfig)
    const targetVolume = purposeTargetVolumeParameter(purposeConfig)
    const minimumPick = purposeMinimumPickParameter(purposeConfig)
    if ([targetMolarity, targetVolume, minimumPick].some((param) => param === undefined)) {
      return {
        valid: false,
        message: 'Tube purpose is not configured for generating transfer volumes',
      }
    } else {
      return validScanMessage()
    }
  }
}

export { checkDuplicates, checkId, checkMatchingPurposes, checkMolarityResult, checkState, checkTransferParameters }
