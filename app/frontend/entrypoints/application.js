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

console.log('Visit the guide for more information: ', 'https://vite-ruby.netlify.app/guide/rails')

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

// Currently setting up each component as its own mini vue app.
import '@/javascript/asset-comments/index.js'
import '@/javascript/custom-tagged-plate/index.js'
import '@/javascript/file-list/index.js'
import '@/javascript/labware-custom-metadata/index.js'
import '@/javascript/multi-stamp-tubes/index.js'
import '@/javascript/multi-stamp/index.js'
import '@/javascript/pipeline-graph/index.js'
import '@/javascript/qc-information/index.js'
import '@/javascript/tubes-to-rack/index.js'
import '@/javascript/validate-paired-tubes/index.js'

// Load simple javascript files
import '@/javascript/plain-javascript/page-reloader.js'
import '@/javascript/plain-javascript/print-scaling'
import '@/javascript/plain-javascript/quadrant-well-failing'
import '@/javascript/plain-javascript/tag-animations' // rotates the displayed tag Id in wells with multiple tags
import '@/javascript/plain-javascript/threshold-well-failing'
