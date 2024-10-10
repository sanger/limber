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
    if (results.length === 0) {
      return { valid: false, message: 'No results retrieved' }
    }

    for (const currTagGroup of results) {
      const hasAllProperties = expectedProperties.every((property) =>
        Object.prototype.hasOwnProperty.call(currTagGroup, property),
      )

      if (!hasAllProperties) {
        return {
          valid: false,
          message: 'Results objects do not contain expected properties',
        }
      }
    }

    return { valid: true, message: 'Results valid' }
  }
}

export { validateError, hasExpectedProperties }
