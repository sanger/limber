// Convenience class for importing multiple factories

import plateFactory from '@/javascript/test_support/factories/plate_factory.js'
import tubeFactory from '@/javascript/test_support/factories/tube_factory.js'
import wellFactory from '@/javascript/test_support/factories/well_factory.js'
import requestFactory from '@/javascript/test_support/factories/request_factory.js'
import {
  jsonFactory,
  jsonCollectionFactory,
  attributesFactory,
} from '@/javascript/test_support/factories/json_factory.js'

const devourFactory = (devour) => {
  return (factoryName, userAttributes = {}) => {
    devour.deserialize.resource(jsonFactory(factoryName, userAttributes))
  }
}

export {
  plateFactory,
  tubeFactory,
  wellFactory,
  requestFactory,
  jsonFactory,
  devourFactory,
  jsonCollectionFactory,
  attributesFactory,
}
