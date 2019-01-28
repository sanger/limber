// Import
import devourClient from 'devour-client'

const devourApi = (apiOptions, resources) => {
  // Initialize the api
  const jsonApi = new devourClient(apiOptions)
  // define the resources
  resources.forEach((resourceConfig)=>{
    jsonApi.define(
      resourceConfig.resource,
      resourceConfig.attributes,
      resourceConfig.options
    )
  })

  return jsonApi
}

export default devourApi
