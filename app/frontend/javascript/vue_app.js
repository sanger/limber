/* eslint no-console: 0 */

import Vue from 'vue'
import { BootstrapVue, BootstrapVueIcons } from 'bootstrap-vue'
import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'
import axios from 'axios'
import cookieJar from '@/javascript/shared/cookieJar.js'
import devourApi from '@/javascript/shared/devourApi.js'
import resources from '@/javascript/shared/resources.js'
import commentStoreFactory from '@/javascript/asset-comments/comment-store.js'
import PoolXPTubeSubmitPanel from '@/javascript/pool-xp-tube-panel/components/PoolXPTubeSubmitPanel.vue'
import AssetComments from '@/javascript/asset-comments/components/AssetComments.vue'
import AssetCommentsCounter from '@/javascript/asset-comments/components/AssetCommentsCounter.vue'
import AssetCommentsAddForm from '@/javascript/asset-comments/components/AssetCommentsAddForm.vue'
import CustomTaggedPlate from '@/javascript/custom-tagged-plate/components/CustomTaggedPlate.vue'
import MainContent from '@/javascript/shared/components/MainContent.vue'
import Page from '@/javascript/shared/components/Page.vue'
import Sidebar from '@/javascript/shared/components/Sidebar.vue'

Vue.use(BootstrapVue)
Vue.use(BootstrapVueIcons)
Vue.component('LbMainContent', MainContent)
Vue.component('LbPage', Page)
Vue.component('LbSidebar', Sidebar)

// Helper function to initialize Vue components
const renderVueComponent = (selector, component, props = {}, data = {}, userIdRequired = false) => {
  const selector_val = `#${selector}`
  const element = document.querySelector(selector_val)
  const userId = cookieJar(document.cookie).user_id
  

  if (element) {
    if (userIdRequired && !userId) {
      debugger
      new Vue({
        el: `#${elementId}`,
        render: (h) => h('div', missingUserIdError),
      })
    } else {
      debugger
      new Vue({
        el: selector_val,
        data: () => data,
        render: (h) => h(component, { props }),
      })
    }
  }
}

const elements = [
  {
    id: 'asset-comments',
    component: AssetCommentsAddForm,
    userIdRequired: true,
  },
  {
    id: 'pool-xp-tube-submit-panel',
    component: PoolXPTubeSubmitPanel,
    userIdRequired: true,
  },
  {
    id: 'custom-tagged-plate-page',
    component: CustomTaggedPlate,
  },
]

document.addEventListener('DOMContentLoaded', () => {
  for (const { id, component, userIdRequired } of elements) {
    const assetElem = document.getElementById(id)
    if (!assetElem) continue
    switch (id) {
      case 'asset-comments': {
        const sequencescapeApiUrl = assetElem.dataset.sequencescapeApi
        const sequencescapeApiKey = assetElem.dataset.sequencescapeApiKey
        const axiosInstance = axios.create({
          baseURL: sequencescapeApiUrl,
          timeout: 10000,
          headers: {
            Accept: 'application/vnd.api+json',
            'Content-Type': 'application/vnd.api+json',
          },
        })
        const api = devourApi({ apiUrl: sequencescapeApiUrl }, resources, sequencescapeApiKey)
        const commentStore = commentStoreFactory(
          axiosInstance,
          api,
          assetElem.dataset.assetId,
          cookieJar(document.cookie).user_id,
        )
        renderVueComponent('asset-comments', AssetComments, {}, commentStore)
        renderVueComponent('asset-comments-counter', AssetCommentsCounter, {}, commentStore)
        renderVueComponent('asset-comments-add-form', component, assetElem.dataset, commentStore, userIdRequired)
        commentStore.refreshComments()
      }
      case 'pool-xp-tube-submit-panel': {
        debugger
        if (
          assetElem.dataset.barcode &&
          assetElem.dataset.sequencescapeApi &&
          assetElem.dataset.tractionServiceUrl &&
          assetElem.dataset.tractionUiUrl
        ) {
          debugger
          renderVueComponent(
            id,
            component,
            {
              barcode: assetElem.dataset.barcode,
              sequencescapeApiUrl: assetElem.dataset.sequencescapeApi,
              tractionServiceUrl: assetElem.dataset.tractionServiceUrl,
              tractionUIUrl: assetElem.dataset.tractionUiUrl,
            },
            {},
            userIdRequired,
          )
        }
        break
      }
      case 'custom-tagged-plate-page': {
        axios.defaults.headers.common['X-CSRF-Token'] = document
          .querySelector('meta[name="csrf-token"]')
          .getAttribute('content')
        Vue.prototype.$axios = axios
        renderVueComponent(id, component, assetElem.dataset, {})
        break
      }
      default:
        console.warn(`No initialization logic defined for element with id: ${id}`)
    }
  }
})
