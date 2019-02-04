/* eslint no-console: 0 */

import Vue from 'vue'
import BootstrapVue from 'bootstrap-vue'
import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'
import CustomTaggedPlate from './components/CustomTaggedPlate.vue'
import MainContent from 'shared/components/MainContent.vue'
import Page from 'shared/components/Page.vue'
import Sidebar from 'shared/components/Sidebar.vue'
import devourApi from 'shared/devourApi'
import resources from 'shared/resources'

Vue.use(BootstrapVue)

Vue.component('lb-main-content', MainContent)
Vue.component('lb-page', Page)
Vue.component('lb-sidebar', Sidebar)

if (process.env.NODE_ENV == 'test') {
  // Vue generates warning if we aren't in the production environment
  // These clutter up the console, but we don't want to turn them off
  // everywhere as they may be useful if we ever end up accidentally
  // running production in development mode. Instead we turn them off
  // explicitly
  Vue.config.productionTip = false
}

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
  const assetElem = document.getElementById('custom-tagged-plate-page')

  if ( assetElem ) {
    /* The custom-tagged-plate-page element isn't on all pages. So only initialize our
    * Vue app if we actually find it */
    // const assetApi = ApiModule({ baseUrl: assetElem.dataset.sequencescapeApi }).Asset
    // const axiosInst = axios.create({
    //   baseURL: assetElem.dataset.sequencescapeApi,
    //   timeout: 10000,
    //   headers: {'Accept': 'application/vnd.api+json', 'Content-Type': 'application/vnd.api+json'}
    // })
    // Vue.prototype.$axios = axiosInst

    // var data = {
    //   // assetApi: assetApi,
    //   axiosSequencescapeInstance: axiosSequencescapeInstance
    // }

    const devApi = devourApi({ apiUrl: assetElem.dataset.sequencescapeApi }, resources)
    Vue.prototype.$api = devApi

    new Vue({
      // Customized render function to pass in properties from our root element
      // Uses render (h) rather than h => to ensure that `this` is the Vue app.
      // Essentially allows any data tags to get passed in to matching properties
      // in App.vue. This lets us mount our app in a variety of contexts, for
      // example showing events for a particular subject, and toggling various
      // navigation elements based on appropriateness
      // h in this case is Vue-shorthand for createElement
      // https://vuejs.org/v2/guide/render-function.html#createElement-Arguments
      render (h) { return h(CustomTaggedPlate, { props: this.$el.dataset }) }
    }).$mount('#custom-tagged-plate-page')
  }
})
