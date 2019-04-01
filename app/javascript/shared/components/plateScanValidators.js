// Plate Scan Validators can be passed in to a PlateScan.vue component to provide
// custom validation.
//
// A validator is a function which:
// 1) Takes the result of the APi query (usually a plate) as a sole argument
// 2) Returns javascript object with two properties:
//    a) valid: A Boolean indicating if the plate is suitable or not
//    b) message: A string which will be displayed to the user. Especially important for failures.
//
// Dynamic validation
// In many case you may want to validate a plate against a dynamic set of criteria, or to provide
// some customization options. In these cases you can wrap your validator in an external function,
// which takes the configuration options as parameters. These parameters will be available to the validator
// function itself.
//
// For example:
// const myValidator(option) => {
//  // This function gets called when the validator is set up. If part of a computed function a new
//  // validator will be generated each time option changes. This will allow validation to respond
//  // dynamically to changes elsewhere on the page.
//  // Typically you only NEED to return the validator function here
//  return (plate) => {
//    // This is the validator itself. It has access to option, and any other parameters defined above
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
// Try and keep validators checking one thing only. It makes them easier to test and reuse. The aggregate
// validator allows you to combine multiple validators together.

// Returns a validator which ensures the plate is of a particular size. For example, to validate your typical
// 12*8 96 well plate:
// checkSize(12,8)
const checkSize = (cols,rows) => {
  return (plate) => {
    if (plate.number_of_columns !== cols || plate.number_of_rows !== rows) {
      return { valid: false, message: `The plate should be ${cols}×${rows} wells in size` }
    } else {
      return { valid: true, message: 'Great!' }
    }
  }
}

// Returns a validator that ensures that the scanned item does not appear multiple times in the
// list (based on UUID). The currentIndex is used to exclude the plate from matching itself, while ensuring
// that validation can take place before emitting the plate to its parent.
// plateList: An array of plates that have already been scanned. Can include null to represent empty plate
// currentIndex: The index of the plate we are currently scanning in the array. Excludes it for the check. (Zero indexed)
const checkDuplicates = (plateList, currentIndex) => {
  return (plate) => {
    const duplicate = plateList.some((other, index) => {
      return index !== currentIndex && // We're not looking at the current plate
        other && other.uuid === plate.uuid // But the uuid matches
    })
    if (duplicate) {
      return { valid: false, message: 'Barcode has been scanned multiple times' }
    } else {
      return { valid: true, message: 'Great!' }
    }
  }
}

// Allows you to combine multiple validators together in a single validator.
// Validators are evaluated from left to right, with lazy evaluation of the failure.
// As a result, the leftmost failing validator will determine the error message.
// eg. aggregate(checkSize(12,8),checkDuplicates(this.plates,0)) will return a validator
// which checks both the size of the plate, and duplications.
const aggregate = (...functions) => {
  return (plate) => {
    return functions.reduce((aggregate, validation)=>{
      return aggregate.valid ? validation(plate) : aggregate
    },{ valid: true, message: 'Great!'})
  }
}

export { checkSize, checkDuplicates, aggregate }
