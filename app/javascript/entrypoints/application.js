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
// import ActiveStorage from '@rails/activestorage'
// ActiveStorage.start()
//
// // Import all channels.
// const channels = import.meta.globEager('./**/*_channel.js')

// Example: Import a stylesheet in app/frontend/index.css
// import '~/index.css'

// Currently setting up each component as its own mini vue app.
import '@/asset-comments/index.js'
import '@/custom-tagged-plate/index.js'
import '@/file-list/index.js'
import '@/labware-custom-metadata/index.js'
import '@/multi-stamp-tubes/index.js'
import '@/multi-stamp/index.js'
import '@/pipeline-graph/index.js'
import '@/qc-information/index.js'
import '@/tubes-to-rack/index.js'
import '@/validate-paired-tubes/index.js'

// Load simple javascript files
import '@/plain-javascript/page-reloader.js'
import '@/plain-javascript/print-scaling'
import '@/plain-javascript/quadrant-well-failing'
import '@/plain-javascript/tag-animations' // rotates the displayed tag Id in wells with multiple tags
import '@/plain-javascript/threshold-well-failing'
