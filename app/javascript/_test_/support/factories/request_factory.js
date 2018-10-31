const requestFactory = function(options = {}) {
  const requestDefaults = {
    uuid: 'request-uuid',
    primerPanel: { name: 'Test panel' }
  }
  return { ... requestDefaults, ...options }
}

export default requestFactory
