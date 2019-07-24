const hasExpectedProperties = (expectedProperties) => {
  return (results) => {
    if(results.length > 0) {
      for (var resultsIndex = 0; resultsIndex < results.length; resultsIndex++) {
        const currTagGroup = results[resultsIndex]
        const expectedPropertiesLength = expectedProperties.length
        for (var propIndex = 0; propIndex < expectedPropertiesLength; propIndex++) {
          const expectedPropertyName = expectedProperties[propIndex]
          if(!currTagGroup.hasOwnProperty(expectedPropertyName)) {
            return { valid: false, message: 'Results objects do not contain expected properties' }
          }
        }
      }
      return { valid: true, message: 'Results valid' }
    } else {
      return { valid: false, message: 'No results retrieved' }
    }
  }
}

export { hasExpectedProperties }
