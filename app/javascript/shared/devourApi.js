// Import
import devourClient from 'devour-client'
import pluralize from 'pluralize'

pluralize.addUncountableRule('labware')

const devourApi = (apiOptions, resources, apiKey) => {
  // Initialize the api
  const jsonApi = new devourClient({ pluralize, ...apiOptions })
  // Add the Sequencescape API key
  jsonApi.headers['X-Sequencescape-Client-Id'] = apiKey
  // define the resources
  resources.forEach((resourceConfig) => {
    jsonApi.define(resourceConfig.resource, resourceConfig.attributes, resourceConfig.options)
  })

  return jsonApi
}

export default devourApi
