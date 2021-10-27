// Receives an array of validators and calls them in the order they appear on
// the array.
// As a result, the smallest indexed failing validator will determine the
// error message and the remaining validators will be skipped.
const aggregate = (validators, item) => {
  return validators.reduce((aggregate, validator) => {
    return aggregate.valid ? validator(item) : aggregate
  }, validScanMessage())
}

// Return object for a valid scan
//
// Returns an object with a scan validation message
const validScanMessage = () => {
  return { valid: true, message: 'Great!' }
}

export { aggregate, validScanMessage }
