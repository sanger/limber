/* eslint no-console: 0 */

import Vue from 'vue'
import { BootstrapVue, BootstrapVueIcons } from 'bootstrap-vue'
import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'
import cookieJar from '@/javascript/shared/cookieJar.js'
import PoolXPTubeSubmitPanel from './components/PoolXPTubeSubmitPanel.vue'

Vue.use(BootstrapVue)
Vue.use(BootstrapVueIcons)
document.addEventListener('DOMContentLoaded', async () => {
  const assetElem = document.getElementById('pool-xp-tube-submit-panel')
  const missingUserIdError = `
    Unfortunately Limber can't find your user id, which is required to add custom metadata.
    Click log out and swipe in again to resolve this.
    If this problem occurs repeatedly, let us know.
  `

  if (assetElem) {
    /* The labware-custom-metadata element isn't on all pages. So only initialize our
     * Vue app if we actually find it */
    const userId = cookieJar(document.cookie).user_id
    const sequencescapeApiUrl = assetElem.dataset.sequencescapeApi
    const tractionServiceUrl = assetElem.dataset.tractionServiceUrl
    const tractionUIUrl = assetElem.dataset.tractionUiUrl
    // UserId is required to make custom metadata, but will not be present in
    // older session cookies. To avoid errors or confusion, we render
    // a very basic vue component (essentially just an error message)
    // if userId is missing

    if (userId) {
      new Vue({
        el: '#pool-xp-tube-submit-panel',
        render(h) {
          let barcode = this.$el.dataset.barcode

          return h(PoolXPTubeSubmitPanel, {
            props: { barcode, userId, sequencescapeApiUrl, tractionServiceUrl, tractionUIUrl },
          })
        },
      })
    } else {
      new Vue({
        el: '#pool-xp-tube-submit-panel',
        render: (h) => h('div', missingUserIdError),
      })
    }
  }
})
