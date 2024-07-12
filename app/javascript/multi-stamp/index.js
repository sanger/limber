/* eslint no-console: 0 */

import Vue from 'vue'
import BootstrapVue from 'bootstrap-vue'
import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'
import MultiStamp from './components/MultiStamp.vue'
import MultiStampLibrarySplitter from './components/MultiStampLibrarySplitter.js'
import MainContent from 'shared/components/MainContent.vue'
import Page from 'shared/components/Page.vue'
import Sidebar from 'shared/components/Sidebar.vue'
import axios from 'axios'

Vue.use(BootstrapVue)

Vue.component('LbMainContent', MainContent)
Vue.component('LbPage', Page)
Vue.component('LbSidebar', Sidebar)

document.addEventListener('DOMContentLoaded', () => {
  /*
   * As we add more components to this page we should
   * consider switching to proper components and custom tags.
   * Ran into a problems as I tried to do this at this stage:
   * 1 - Vue needs to compile the template (ie. our HTML) on the fly
   #     which means we import a different version of vue above.
   #     import Vue from 'vue/dist/vue.esm'
   #     This is slower, and generally recommended against.
   # 2 - Things didn't appear to be as straight forward as I
   #     had hoped. I *think* this was because I began wrestling
   #     vue's expectations with regards to single page applications
   # 3 - Vue does NOT like our existing templates. The script tags
   #     seem to upset it.
   # In general it looks like this is something we should consider
   # once the majority of our components are vue based.
   */
  if (document.getElementById('multi-stamp-page')) {
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
        return h(MultiStamp, { props: this.$el.dataset })
      },
    }).$mount('#multi-stamp-page')
  }

  if (document.getElementById('multi-stamp-library-splitter-page')) {
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
        return h(MultiStampLibrarySplitter, { props: this.$el.dataset })
      },
    }).$mount('#multi-stamp-library-splitter-page')
  }
})
