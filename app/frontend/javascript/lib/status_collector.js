// A status collector can have monitors registered. It will trigger
// its onSuccess event when all monitors are true, and its onRevert
// event if any are false.
let statusCollector = function (onSuccess, onRevert) {
  // Fires when all guards are true
  this.onSuccess = onSuccess
  // Fires if a guard is invalidated
  this.onRevert = onRevert
  this.monitors = []
}

// Monitors are registered to a collector. When the change state they
// trigger the collector to check the state of all its monitors.
let monitor = function (state, collector) {
  this.valid = state || false
  this.collector = collector
}

monitor.prototype = {
  pass: function () {
    this.valid = true
    this.collector.collate()
  },
  fail: function () {
    this.valid = false
    this.collector.collate()
  },
}

statusCollector.prototype = {
  register: function (status) {
    let new_monitor = new monitor(status, this)
    this.monitors.push(new_monitor)
    return new_monitor
  },
  collate: function () {
    for (let i = 0; i < this.monitors.length; i += 1) {
      if (!this.monitors[i].valid) {
        return this.onRevert()
      }
    }
    return this.onSuccess()
  },
}

export default statusCollector
