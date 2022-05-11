import resources from 'shared/resources'

// Reads in the shared resources file and provides some friendly interfaces
export default class ResourceConfig {
  constructor(resource_name) {
    this.resource_config = resources.find((resource) => {
      return resource.resource === resource_name
    })
  }
  get invalid() {
    return this.resource_config === undefined
  }
  get attributes() {
    return Object.entries(this.resource_config.attributes).reduce((attributes, [name, options]) => {
      if (!(options instanceof Object)) {
        attributes.push(name)
      }
      return attributes
    }, [])
  }
  get associations() {
    return Object.entries(this.resource_config.attributes).reduce((attributes, [name, options]) => {
      if (options instanceof Object) {
        attributes.push(name)
      }
      return attributes
    }, [])
  }
}
