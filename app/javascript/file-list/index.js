/* eslint no-console: 0 */

import Vue from 'vue'
import FileList from './components/FileList.vue'

document.addEventListener('DOMContentLoaded', () => {
  var app = new Vue({
    el: '#files-list',
    render: h => h(FileList)
  });
  window.globo = app;
  $('#files-tab-link').on('click',function() { app.$children[0].fetchData(); })
})
