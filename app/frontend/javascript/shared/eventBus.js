// Vue application event bus
// Based on https://blog.logrocket.com/using-event-bus-vue-js-pass-data-between-components/

// See 'Event Bus' section at https://v3-migration.vuejs.org/breaking-changes/events-api
import emitter from 'tiny-emitter/instance'

export default {
  $on: (...args) => emitter.on(...args),
  $once: (...args) => emitter.once(...args),
  $off: (...args) => emitter.off(...args),
  $emit: (...args) => emitter.emit(...args),
}
