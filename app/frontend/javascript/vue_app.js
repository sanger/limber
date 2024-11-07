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
import FileList from '@/javascript/file-list/components/FileList.vue'
import LabwareCustomMetadataAddForm from '@/javascript/labware-custom-metadata/components/LabwareCustomMetadataAddForm.vue'
import MultiStamp from '@/javascript/multi-stamp/components/MultiStamp.vue'
import MultiStampLibrarySpliter from '@/javascript/multi-stamp/components/MultiStampLibrarySplitter.js'
import MultiStampTubes from '@/javascript/multi-stamp-tubes/components/MultiStampTubes.vue'
import QcInformation from '@/javascript/qc-information/components/QcInformation.vue'
import TubesToRack from '@/javascript/tubes-to-rack/components/TubesToRack.vue'
import ValidatePairedTubes from '@/javascript/validate-paired-tubes/components/ValidatePairedTubes.vue'


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
      new Vue({
        el: `#${elementId}`,
        render: (h) => h('div', missingUserIdError),
      })
    } else {
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
  {
    id: 'file-list',
    component: FileList,
  },
  {
    id: 'labware-custom-metadata-add-form',
    component: LabwareCustomMetadataAddForm,
    userIdRequired: true,
  },
  {
    id: 'multi-stamp-page',
    component: MultiStamp,
  },
  {
    id: 'multi-stamp-library-splitter-page',
    component: MultiStampLibrarySpliter,
  },
  {
    id: 'multi-stamp-tubes-page',
    component: MultiStampTubes,
  },
  {
    id: 'qc-information',
    component: QcInformation,
  },
  {
    id: 'tubes-to-rack',
    component: TubesToRack,
  },
  {
    id: 'validate-paired-tubes',
    component: ValidatePairedTubes,
  }
]

const setAxiosHeaderToken = () => {
  axios.defaults.headers.common['X-CSRF-Token'] = document
    .querySelector('meta[name="csrf-token"]')
    .getAttribute('content')
  Vue.prototype.$axios = axios
}

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
        if (
          assetElem.dataset.barcode &&
          assetElem.dataset.sequencescapeApi &&
          assetElem.dataset.tractionServiceUrl &&
          assetElem.dataset.tractionUiUrl
        ) {
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
      case 'file-list': {
        renderVueComponent(id, component, {}, {})
        document.getElementById(id).addEventListener('click', function () {
          app.$children[0].fetchData()
        })
        break
      }
      case 'labware-custom-metadata-add-form': {
        renderVueComponent(
          id,
          component,
          {
            labwareId: assetElem.dataset.labwareId,
            sequencescapeApiUrl: assetElem.dataset.sequencescapeApi,
            sequencescapeUrl: assetElem.dataset.sequencescapeUrl,
            tractionUIUrl: assetElem.dataset.tractionUiUrl,
            customMetadataFields: assetElem.dataset.customMetadataFields,
          },
          {},
          userIdRequired,
        )
        break
      }
      case 'multi-stamp-page':
      case 'multi-stamp-library-splitter-page':
      case 'multi-stamp-tubes-page':
      case 'custom-tagged-plate-page': 
      case 'tubes-to-rack':
        case 'validate-paired-tubes': {
        setAxiosHeaderToken()
        renderVueComponent(id, component, assetElem.dataset, {})
        break
      }
      case 'qc-information': {
        renderVueComponent(id, component, assetElem.dataset, {})
        break
      }
      default:
        console.warn(`No initialization logic defined for element with id: ${id}`)
    }
  }
})
