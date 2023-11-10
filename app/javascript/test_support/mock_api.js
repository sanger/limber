/*
Mock the devour api to allow us to test the UI without making real requests to
the server. This is done by adding a mock middleware to the devour api. The
mock middleware intercepts requests and returns a mocked response. The mocked
response is defined by calling mockGet() or mockFail() on the mock middleware.
*/

import devourApi from 'shared/devourApi'
import sequencescapeResources from 'shared/resources'
// Provides object equality comparisons. eg.
// isEqual({a:'1'},{a:'1'}) > true
import isEqual from 'fast-deep-equal'

const dummyApiUrl = 'http://www.example.com'
const dummyApiKey = 'mock_api_key'

// Nice user readable summary of the request object
const requestFormatter = function (request) {
  // order keys alphabetically
  const sorted_keys = Object.keys(request.params).sort()
  const parameters = sorted_keys.map((key) => `"${key}": ${JSON.stringify(request.params[key])}`).join(', ')
  return `
  --------------------------------------------------------------------------------
  Method: ${request.method}
  Url:    ${request.url}
  Params: {${parameters}}
  --------------------------------------------------------------------------------
  `.trim()
}

// Fail the test if we receive an unexpected request and provide information
// to assist with debugging
const raiseUnexpectedRequest = (request, expectedRequests) => {
  const formattedExpectedRequests = expectedRequests.map((req) => requestFormatter(req.req)).join('\n  ')
  const formattedRequest = requestFormatter(request)
  throw new Error(`
  Unexpected request:
  ${formattedRequest}
  Expected one of:
  ${formattedExpectedRequests}`)
}

const mockApi = function (resources = sequencescapeResources) {
  const devour = devourApi({ apiUrl: dummyApiUrl }, resources, dummyApiKey)
  const mockedRequests = []
  // Find a request in the mockedRequests array that matches the request
  // object. If no match is found, return undefined.
  const findRequest = (request) => {
    return mockedRequests.find((requestResponse) => {
      // devour is a little inconsistent in when it records a data payload
      // findAll() for instant leaves data undefined, whereas some of the url
      // generation routes (such as grabbing relationships) send an empty object
      const { method, url, params, data = {} } = request
      return isEqual(requestResponse.req, { method, url, params, data })
    })
  }

  const mockResponseMiddleware = {
    name: 'mock-request-response',
    mockedRequests: [],
    req: (payload) => {
      const incomingRequest = payload.req
      const mockedRequest = findRequest(incomingRequest)

      if (mockedRequest) {
        incomingRequest.adapter = function () {
          return mockedRequest.res
        }
      } else {
        // Stop things going further, otherwise we risk generating real traffic
        incomingRequest.adapter = function () {
          return Promise.reject({ message: 'unregistered request' })
        }
        raiseUnexpectedRequest(incomingRequest, mockedRequests)
      }

      return payload
    },
    mockGet: (url, params, response) => {
      mockedRequests.unshift({
        req: { method: 'GET', url: `${dummyApiUrl}/${url}`, data: {}, params }, // Request
        res: Promise.resolve({ data: response }), // Response
      })
    },
    mockFail: (url, params, response) => {
      mockedRequests.unshift({
        req: { method: 'GET', url: `${dummyApiUrl}/${url}`, data: {}, params }, // Request
        res: Promise.reject({ data: response }), // Response
      })
    },
    devour,
  }

  // Ensure that a 'mock-request-response' middleware is always present in
  // the devour.middleware array, either by adding a new one or replacing an existing one.
  let mockMiddlewareIndex = devour.middleware.findIndex((mw) => {
    mw.name === 'mock-request-response'
  })
  if (mockMiddlewareIndex === -1) {
    devour.middleware.unshift(mockResponseMiddleware)
  } else {
    devour.middleware[mockMiddlewareIndex] = mockResponseMiddleware
  }

  return mockResponseMiddleware
}

export default mockApi
