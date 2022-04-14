/* eslint no-console: 0 */

import Vue from 'vue'
import BootstrapVue from 'bootstrap-vue'
import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'
import MultiStampTubes from './components/MultiStampTubes.vue'
import MainContent from 'shared/components/MainContent.vue'
import Page from 'shared/components/Page.vue'
import Sidebar from 'shared/components/Sidebar.vue'
import axios from 'axios'

Vue.use(BootstrapVue)

Vue.component('lb-main-content', MainContent)
Vue.component('lb-page', Page)
Vue.component('lb-sidebar', Sidebar)

document.addEventListener('DOMContentLoaded', () => {
  if (document.getElementById('multi-stamp-tubes-page')) {
    axios.defaults.headers.common['X-CSRF-Token'] = document
      .querySelector('meta[name="csrf-token"]')
      .getAttribute('content')
    Vue.prototype.$axios = axios
    /* The files-list element isn't on all pages. So only initialize our
     * Vue app if we actually find it */
    new Vue({
      // Customized render function to pass in properties from our root element
      // Uses render (h) rather than h => to ensure that `this` is the Vue app.
      // Essentially allows any data tags to get passed in to matching properties
      // in App.vue. This lets us mount our app in a variety of contexts, for
      // example showing events for a particular subject, and toggling various
      // navigation elements based on appropriateness
      // h in this case is Vue-shorthand for createElement
      // https://vuejs.org/v2/guide/render-function.html#createElement-Arguments
      render(h) {
        return h(MultiStampTubes, { props: this.$el.dataset })
      },
    }).$mount('#multi-stamp-tubes-page')
  }
})
