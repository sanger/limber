import buildArray from '@/javascript/shared/buildArray.js'
import requestFactory from '@/javascript/test_support/factories/request_factory.js'

// Probably move outside
const wellFactory = function (options = {}) {
  const uuid = options.uuid || 'well-uuid'
  const wellDefaults = {
    uuid: uuid,
    position: { name: 'A1' },
    requests_as_source: buildArray(1, (iteration) => requestFactory({ uuid: `${uuid}-source-request-${iteration}` })),
    aliquots: [{ request: null }],
  }
  return { ...wellDefaults, ...options }
}

export default wellFactory
