// To see this message, add the following to the `<head>` section in your
// views/layouts/application.html.erb
//
//    <%= vite_client_tag %>
//    <%= vite_javascript_tag 'application' %>
console.log('Vite ⚡️ Rails')

// If using a TypeScript entrypoint file:
//     <%= vite_typescript_tag 'application' %>
//
// If you want to use .jsx or .tsx, add the extension:
//     <%= vite_javascript_tag 'application.jsx' %>

// console.log('Visit the guide for more information: ', 'https://vite-ruby.netlify.app/guide/rails')

// Example: Load Rails libraries in Vite.
//
// import * as Turbo from '@hotwired/turbo'
// Turbo.start()
//
// import ActiveStorage from '@rails/activestorage.vue'
// ActiveStorage.start()
//
// // Import all channels.
// const channels = import.meta.globEager('./**/*_channel.js')

// Example: Import a stylesheet in app/frontend/index.css
// import '~/index.css'

// ^^^ Template from Vite. Below is custom code for Limber ^^^

// Import Rails UJS as in Sequencescape
import Rails from '@rails/ujs'

try {
  Rails.start()
} catch {
  // Nothing
}

// Import Libraries
import 'bootstrap'

// Load all javascript files previously in the app/assets directory
import '@/javascript/legacy_scripts_a.js'
import '@/javascript/session_scripts.js'
import '@/javascript/state_change_reasons.js'
import '@/javascript/state_machine.js'
import '@/javascript/tooltips.js'
// Load all javascript files previously in the app/assets/lib directory, these really should
// be loaded as required, not globally as previously done.
import '@/javascript/lib/ajax_support.js'
import '@/javascript/lib/array_fill_polyfill.js'

// Currently setting up each component as its own mini vue app.
import '@/javascript/vue_app.js'

// Load simple javascript files
import '@/javascript/plain-javascript/page-reloader.js'
import '@/javascript/plain-javascript/print-scaling.js'
import '@/javascript/plain-javascript/quadrant-well-failing.js'
import '@/javascript/plain-javascript/tag-animations.js' // rotates the displayed tag Id in wells with multiple tags
import '@/javascript/plain-javascript/threshold-well-failing.js'
