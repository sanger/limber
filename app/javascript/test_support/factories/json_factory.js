// Convenience class for importing multiple factories

import counter from 'test_support/counter'
import uuidv4 from 'uuid/v4'
import pluralize from 'pluralize'
import defaults from 'test_support/factories/defaults'
import ResourceConfig from './resource_config'

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
// Attributes listed here will only appear in the generated object if listed as
// attributes in the corresponding resource
const globalDefaults = (_id) => {
  return {
    uuid() { return uuidv4() },
    created_at() { return (new Date).toJSON() },
    updated_at() { return (new Date).toJSON() }
  }
}

// Extracts the attributes for the given resource
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

// The relationship links for a given association
const relationLinks = (resourceUrl, associationName) => {
  return { links: {
    self: `${resourceUrl}/relationships/${associationName}`,
    related: `${resourceUrl}/${associationName}`
  }}
}

// Extracts and builds the associations for a given resource
const extractAssociations = (resource_config, attributeValues, resourceUrl) => {
  return resource_config.associations.reduce(({ relationships, included }, associationName) => {
    const { relationData, includeData } = associationData(associationName, attributeValues[associationName])
    relationships[associationName] = {
      ... relationLinks(resourceUrl, associationName),
      ... relationData
    }
    included.push(...includeData)

    return { relationships, included }
  }, { relationships: {}, included: []})
}

const associationData = (associationName, associationValue) => {
  if (!associationValue) {
    // We have no association
    return { relationData: {}, includeData: [] }
  } else if (associationValue instanceof Array) {
    return buildMany(associationName, associationValue)
  } else {
    return buildOne(associationName, associationValue)
  }
}

const buildMany = (associationName, associationValue) => {
  return associationValue.reduce(({ relationData, includeData }, resourceValue) => {
    const singleResource = buildOne(associationName, resourceValue)
    relationData.data.push(singleResource.relationData.data)
    includeData.push(...singleResource.includeData)
    return { relationData, includeData }
  }, { relationData: { data: [] }, includeData: [] })
}

const buildOne = (associationName, associationValue) => {
  const { _factory = pluralize.singular(associationName), ...childAttributes } = associationValue
  const childJson = jsonFactory(_factory, childAttributes).data
  const { included: childIncluded = [], ... childData } = childJson
  return {
    relationData: { data: { id: childJson.id, type: childJson.type } },
    includeData: [...childIncluded, childData]
  }
}


/**
 * Build a jsonApi representation of your resource
 * @param {string} resource - The resource type to construct or a factory
 * @param {object} attributes - Any custom attributes to override the defaults
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
      relationships
    },
    included
  }
}

export default jsonFactory
