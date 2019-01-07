import buildArray from 'shared/buildArray'
import requestFactory from 'test_support/factories/request_factory'

// Probably move outside
const wellFactory = function(options = {}) {
  const uuid = options.uuid || 'well-uuid'
  const wellDefaults = {
    uuid: uuid,
    position: { name: 'A1' },
    requestsAsSource: buildArray(1, (iteration) => requestFactory({ uuid: `${uuid}-source-request-${iteration}` })),
    aliquots: [{ request: null }]
  }
  return {  ...wellDefaults, ...options }
}

export default wellFactory
