const requestFactory = function(options = {}) {
  const requestDefaults = {
    uuid: 'request-uuid',
    primer_panel: { name: 'Test panel' },
    state: 'started'
  }
  return { ...requestDefaults, ...options }
}

export default requestFactory
