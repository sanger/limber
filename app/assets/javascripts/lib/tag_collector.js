// A status collector can have monitors registered. It will trigger
// its onSuccess event when all monitors are true, and its onRevert
// event if any are false.
var tagStatusCollector = function (dualRequired, onSuccess, onRevert) {
  // Fires when all guards are true
  this.onSuccess = onSuccess
  // Fires if a guard is invalidated
  this.onRevert = onRevert

  this.dualRequired = dualRequired
  this.monitors = []
}

// Monitors are registered to a collector. When the change state they
// trigger the collector to check the state of all its monitors.
var tagMonitor = function (state, collector, monitored) {
  this.valid = state || false
  this.collector = collector
  this.monitored = monitored
}

tagMonitor.prototype = {
  pass: function () {
    this.valid = true
    this.collector.collate()
  },
  fail: function () {
    this.valid = false
    this.collector.collate()
  },
  dual: function () {
    return this.monitored.dual()
  },
}

tagStatusCollector.prototype = {
  register: function (status, monitored) {
    var new_monitor = new tagMonitor(status, this, monitored)
    this.monitors.push(new_monitor)
    return new_monitor
  },
  collate: function () {
    var dual_count = 0
    for (var i = 0; i < this.monitors.length; i += 1) {
      if (!this.monitors[i].valid) {
        return this.onRevert()
      }
      if (this.monitors[i].dual()) {
        dual_count += 1
      }
    }
    return this.checkDual(dual_count)
  },
  checkDual: function (dual_count) {
    if (dual_count > 1) {
      return this.onRevert('Can not use UDI plates with tubes. Only one source of i7 tags is permitted.')
    } else if (dual_count === 0 && this.dualRequired) {
      return this.onRevert('No i7 tag supplied.')
    } else {
      return this.onSuccess()
    }
  },
}
