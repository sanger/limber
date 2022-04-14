import devourApi from 'shared/devourApi'
import sequencescapeResources from 'shared/resources'
// Provides object equality comparisons. eg.
// isEqual({a:'1'},{a:'1'}) > true
import isEqual from 'fast-deep-equal'

const dummyApiUrl = 'http://www.example.com'

// Nice user readable summary of the request object
const requestFormatter = function (request) {
  return `
--------------------------------------------------------------------------------
  Method: ${request.method}
  Url:    ${request.url}
  Params: ${JSON.stringify(request.params)}
--------------------------------------------------------------------------------
  `
}

// Fail the test if we receive an unexpected request and provide information
// to assist with debugging
const unexpectedRequest = function (request, expectedRequests) {
  const baseError = `Unexpected Request:
${requestFormatter(request)}
Expected Requests:`
  const errorMessage = expectedRequests.reduce((error, expectedRequest) => {
    return error + requestFormatter(expectedRequest.req)
  }, baseError)
  fail(errorMessage)
}

const mockApi = function (resources = sequencescapeResources) {
  const devour = devourApi({ apiUrl: dummyApiUrl }, resources)
  const mockedRequests = []
  const findRequest = (request) => {
    return mockedRequests.find((requestResponse) => {
      // devour is a little inconsistent in when it records a data payload
      // findAll() for instant leaves data undefined, whereas some of the url
      // generation routes (such as grabbing relationships) send an empty object
      const { method, url, params, data = {} } = request
      return isEqual(requestResponse.req, { method, url, params, data })
    })
  }

  const mockResponse = {
    name: 'mock-request-response',
    mockedRequests: [],
    req: (payload) => {
      const mockedRequest = findRequest(payload.req)

      if (mockedRequest) {
        mockedRequest.called += 1
        payload.req.adapter = function () {
          return mockedRequest.res
        }
      } else {
        // Stop things going further, otherwise we risk generating real traffic
        payload.req.adapter = function () {
          return Promise.reject({ message: 'unregistered request' })
        }
        unexpectedRequest(payload.req, mockedRequests)
      }
      return payload
    },
    mockGet: (url, params, response) => {
      mockedRequests.unshift({
        req: { method: 'GET', url: `${dummyApiUrl}/${url}`, data: {}, params }, // Request
        res: Promise.resolve({ data: response }), // Response
        called: 0,
      })
    },
    mockFail: (url, params, response) => {
      mockedRequests.unshift({
        req: { method: 'GET', url: `${dummyApiUrl}/${url}`, data: {}, params }, // Request
        res: Promise.reject({ data: response }), // Response
        called: 0,
      })
    },
    devour,
  }

  let mockMiddlewareIndex = devour.middleware.findIndex((mw) => {
    mw.name === 'mock-request-response'
  })

  if (mockMiddlewareIndex === -1) {
    devour.middleware.unshift(mockResponse)
  } else {
    devour.middleware[mockMiddlewareIndex] = mockResponse
  }

  return mockResponse
}

export default mockApi
