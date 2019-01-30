// Convenience class for importing multiple factories

import plateFactory from 'test_support/factories/plate_factory.js'
import wellFactory from 'test_support/factories/well_factory.js'
import requestFactory from 'test_support/factories/request_factory.js'
import counter from 'test_support/counter'
import uuidv4 from 'uuid/v4'
import pluralize from 'pluralize'
import defaults from 'test_support/factories/defaults'
import ResourceConfig from './factories/resource_config'

// Thrown if we request an unrecognized factory.
class InvalidFactory extends Error {
  constructor(factory, resource_name) {
    super(`Unrecognized factory '${factory}' or resource '${resource_name}'.
    Factory should either be a singular resource type (eg. 'plate')
    or a named factory from test_support/factories/defaults.
    Named factories not matching a resource name MUST specify one via the resource attribute.`)
  }
}
const dummyApiUrl = 'http://www.example.com'
// Returns the name of a resource for a given factory
const resourceName = factoryName =>  defaults[factoryName] && defaults[factoryName].resource || factoryName

const nextIndex = counter(1)

// Provides the default value for a given attribute across ALL factories.
// Attributes listed here will only appear in the generated object if listed as attributes in the corresponding
// resource
const globalDefaults = (_id) => {
  return {
    uuid() { return uuidv4() },
    created_at() { return (new Date).toJSON() },
    updated_at() { return (new Date).toJSON() }
  }
}

const extractAttributes = (resource_config, attributeValues) => {
  return resource_config.attributes.reduce((attributeSet, attributeName) => {
    const attributeValue = attributeValues[attributeName]
    if (attributeValue instanceof Function) {
      attributeSet[attributeName] = attributeValue.call()
    } else {
      attributeSet[attributeName] = attributeValue
    }
    return attributeSet
  }, {})
}

const extractAssociations = (resource_config, attributeValues, resourceUrl) => {
  return resource_config.associations.reduce(({ relationships, included }, associationName) => {
    relationships[associationName] = {
      links: {
        self: `${resourceUrl}/relationships/${associationName}`,
        related: `${resourceUrl}/${associationName}`
      }
    }

    if (attributeValues[associationName]) {
      const { _factory = associationName, ...childAttributes } = attributeValues[associationName]
      const childJson = jsonFactory(_factory, childAttributes).data
      const { id, type } = childJson
      const { included: childIncluded = [], ... childData } = childJson
      relationships[associationName].data = { id, type }
      included.unshift(...childIncluded, childData)
    }

    return { relationships, included }
  }, { relationships: {}, included: []})
}

/**
 * Build a jsonApi representation of your resource
 * @param {string} resource - The resource type to construct or a factory
 * @param {object} attributes - Any custom attributes to override the defaults
 * @param {object} options - Additional options, especially those regarding relationships
 */
const jsonFactory = (factoryName, userAttributes = {}) => {
  const factory = defaults[factoryName] || { attributes: {} }
  const type = resourceName(factoryName)
  const resource_config = new ResourceConfig(type)

  // We don't recognise the factory.
  if (resource_config.invalid) { throw new InvalidFactory(factoryName, type) }

  const { id = nextIndex() } = userAttributes
  const resourceUrl = `${dummyApiUrl}/${pluralize(type)}/${id}`
  const links = { self: resourceUrl }

  const attributeValues = { ... globalDefaults(id), ... factory.attributes, ... userAttributes }

  const attributes = extractAttributes(resource_config, attributeValues)
  const { relationships, included } = extractAssociations(resource_config, attributeValues, resourceUrl)

  return {
    data: {
      id,
      type: pluralize(type),
      links,
      attributes,
      relationships,
      included
    }
  }
}

export { plateFactory, wellFactory, requestFactory, jsonFactory }
