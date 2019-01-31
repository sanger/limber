// Convenience class for importing multiple factories

import plateFactory from 'test_support/factories/plate_factory.js'
import wellFactory from 'test_support/factories/well_factory.js'
import requestFactory from 'test_support/factories/request_factory.js'
import jsonFactory from 'test_support/factories/json_factory'

const devourFactory = (devour) => {
  return (factoryName, userAttributes = {}) => {
    const json = jsonFactory(factoryName, userAttributes)
  }
}

export { plateFactory, wellFactory, requestFactory, jsonFactory }
