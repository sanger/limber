/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.
//
// To reference this file, add <%= javascript_pack_tag 'pipeline-graph' %> to the appropriate
// file

// This is kept distinct from the application.js as the graph library is pretty large,
// and yet is only used on the pipelines page.

// Currently setting up each component as its own mini vue app.
require('pipeline-graph')
