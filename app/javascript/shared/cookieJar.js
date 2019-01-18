
const splitOnSemiColonOptionalSpace = /;\s{0,1}/

// Splits the cookie string into a js object
// document.cookies returns a string of all the cookies
// separated by semi-colons. eg.
// cookie1=value1; cookie2=value2; cookie3=value3;
// A space SHOULD follow on from the semi-colon, but not all browsers
// obey this.
// https://developer.mozilla.org/en-US/docs/Web/API/Document/cookie
// This splits the cookie object into a simple js object consisting of
// key-value pairs.
const cookieJar = function(cookies) {
  let keyValues = cookies.split(splitOnSemiColonOptionalSpace)
  let store = {}
  keyValues.forEach(function(keyValue) {
    let splitOn = keyValue.search('=')
    let key = keyValue.substring(0, splitOn)
    let value = keyValue.substring(splitOn + 1)
    store[key] = value
  })
  return store
}

export default cookieJar
