/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'application' %> to the appropriate
// layout file, like app/views/layouts/application.html.erb

// Currently setting up each component as its own mini vue app.
require('asset-comments')
require('custom-tagged-plate')
require('file-list')
require('multi-stamp')
require('multi-stamp-tubes')
require('qc-information')
require('transfer-volumes')
require('tubes-to-rack')

// Load simple javscripts
// Tag animations rotates the displayed tag Id in wells with multiple tags
require('plain-javascript/tag-animations')
require('plain-javascript/page-reloader')
require('plain-javascript/quadrant-well-failing')
require('plain-javascript/threshold-well-failing')
