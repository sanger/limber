const validateError = (response) => {
  // switch statement on 'response' against differing error formats
  // falsy -> { state: 'invalid', message: 'Unknown error' }
  // {0: {title: '...', detail: '...'}} -> { state: 'invalid', message: '...' }
  // default -> { ...response, state: 'invalid' }
  let errorResponse
  switch (true) {
    case !response:
      errorResponse = { state: 'invalid', message: 'Unknown error' }
      break
    case Boolean(response[0] && response[0].title && response[0].detail):
      errorResponse = { state: 'invalid', message: `${response[0].title}: ${response[0].detail}` }
      break
    default:
      errorResponse = { ...response, state: 'invalid' }
  }
  return errorResponse
}

const hasExpectedProperties = (expectedProperties) => {
  return (results) => {
    if (results.length > 0) {
      for (var resultsIndex = 0; resultsIndex < results.length; resultsIndex++) {
        const currTagGroup = results[resultsIndex]
        const expectedPropertiesLength = expectedProperties.length
        for (var propIndex = 0; propIndex < expectedPropertiesLength; propIndex++) {
          const expectedPropertyName = expectedProperties[propIndex]
          if (!Object.prototype.hasOwnProperty.call(currTagGroup, expectedPropertyName)) {
            return {
              valid: false,
              message: 'Results objects do not contain expected properties',
            }
          }
        }
      }
      return { valid: true, message: 'Results valid' }
    } else {
      return { valid: false, message: 'No results retrieved' }
    }
  }
}

export { validateError, hasExpectedProperties }
