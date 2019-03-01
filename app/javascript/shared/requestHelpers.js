const requestIsActive = function(request) {
  return request.state !== 'passed' &&
    request.state !== 'cancelled' &&
    request.state !== 'failed'
}

export default requestIsActive
