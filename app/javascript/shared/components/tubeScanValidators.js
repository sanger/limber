// Tube Scan Validators can be passed in to a LabwareScan.vue component to
// provide custom validation.
//
// A validator is a function which:
// 1) Takes the result of the APi query (usually a tube) as a sole argument
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
// Try and keep validators checking one thing only. It makes them easier to
// test and reuse. The aggregate validator allows you to combine multiple
// validators together.

// Returns a validator that ensures that the scanned item does not appear
// multiple times in the list (based on UUID).
// tubeList: An array of tubes that have already been scanned. Can include
//           null to represent empty tube
const checkDuplicates = (tubeList) => {
  return (tube) => {
    let occurrences = 0
    for (let i = 0; i < tubeList.length; i++) {
      if (tubeList[i] && tube && tubeList[i].uuid === tube.uuid) { occurrences++ }
    }
    if (occurrences > 1) {
      return { valid: false, message: 'Barcode has been scanned multiple times' }
    }
    else {
      return validTubeScanMessage()
    }
  }
}

// Renders a valid Tube scan
// 
// Returns an object with the right tube scan validation message
const validTubeScanMessage = () => {
  return { valid: true, message: 'Great!' }
}

// Returns a validator that ensures the tube has a state that matches to the
// supplied list of states. e.g. to check a tube has a state of 'available'
// or 'exhausted':
// checkState(['available', 'exhausted'])
const checkState = (allowedStatesList) => {
  return (tube) => {
    if(!allowedStatesList.includes(tube.state)) {
      return { valid: false, message: 'Tube must have a state of: ' + allowedStatesList.join(' or ') }
    } else {
      return { valid: true, message: 'Great!' }
    }
  }
}

// Receives an array of validators and calls them in the order they appear on
// the array.
// As a result, the smallest indexed failing validator will determine the
// error message and the remaining validators will be skipped.
const aggregate = (validators, item) => {
  return validators.reduce((aggregate, validator) => {
    return aggregate.valid ? validator(item) : aggregate
  }, { valid: true, message: 'Great!'})
}

export { checkDuplicates, checkState, aggregate, validTubeScanMessage }
