/* eslint no-console: 0 */

import { createApp, h } from 'vue'
import { createBootstrap } from 'bootstrap-vue-next'
import 'bootstrap-vue-next/dist/bootstrap-vue-next.css'
import axios from 'axios'
import cookieJar from '@/javascript/shared/cookieJar.js'
import PoolXPTubeSubmitPanel from '@/javascript/pool-xp-tube-panel/components/PoolXPTubeSubmitPanel.vue'
import AssetComments from '@/javascript/asset-comments/components/AssetComments.vue'
import AssetCommentsCounter from '@/javascript/asset-comments/components/AssetCommentsCounter.vue'
import AssetCommentsAddForm from '@/javascript/asset-comments/components/AssetCommentsAddForm.vue'
import BlendedTube from '@/javascript/blended-tube/components/BlendedTube.vue'
import CustomTaggedPlate from '@/javascript/custom-tagged-plate/components/CustomTaggedPlate.vue'
import FileList from '@/javascript/file-list/components/FileList.vue'
import LabwareCustomMetadataAddForm from '@/javascript/labware-custom-metadata/components/LabwareCustomMetadataAddForm.vue'
import MultiStamp from '@/javascript/multi-stamp/components/MultiStamp.vue'
import MultiStampLibrarySplitter from '@/javascript/multi-stamp/components/MultiStampLibrarySplitter.js'
import MultiStampTubes from '@/javascript/multi-stamp-tubes/components/MultiStampTubes.vue'
import QcInformation from '@/javascript/qc-information/components/QcInformation.vue'
import TubesToRack from '@/javascript/tubes-to-rack/components/TubesToRack.vue'
import ValidatePairedTubes from '@/javascript/validate-paired-tubes/components/ValidatePairedTubes.vue'

import MainContent from '@/javascript/shared/components/MainContent.vue'
import Page from '@/javascript/shared/components/Page.vue'
import Sidebar from '@/javascript/shared/components/Sidebar.vue'

export const missingUserIdError = `
    Unfortunately Limber can't find your user id, which is required to add custom metadata.
    Click log out and swipe in again to resolve this.
    If this problem occurs repeatedly, let us know.`

/**
 * Helper function to initialize and render a Vue component.
 *
 * @param {string} selector - The CSS selector of the DOM element to mount the Vue instance on.
 * @param {Object} component - The Vue component to render.
 * @param {Object} [props={}] - The props to pass to the Vue component.
 * @param {Object} [data={}] - The data to pass to the Vue instance.
 * @param {boolean} [userIdRequired=false] - Whether a user ID is required to render the component.
 * @returns {Vue} The Vue instance.
 */

export const renderVueComponent = (selector, component, props = {}, userIdRequired = false) => {
  const selector_val = `#${selector}`
  const element = document.querySelector(selector_val)
  const userId = cookieJar(document.cookie).user_id
  if (!element) {
    console.error(`Element with selector ${selector_val} not found.`)
    return
  }

  let app
  if (userIdRequired && !userId) {
    const component_name = component.name
    console.warn(`User id is required to render the ${component_name} component.`)
    app = createApp({
      render: () => h('div', missingUserIdError),
    })
  } else {
    props.userId = userId
    app = createApp({
      render: () => h(component, props),
    })
  }
  app.use(createBootstrap())

  app.component('LbMainContent', MainContent)
  app.component('LbPage', Page)
  app.component('LbSidebar', Sidebar)

  setAxiosHeaderToken(app)
  app.mount(selector_val)
  return app
}

/**
 * List of elements to initialize as Vue components.
 * Each element should have an id, a Vue component, an optional flag indicating whether a user ID is required and a setData method.
 */
const elements = [
  {
    id: 'asset-comments-add-form',
    component: AssetCommentsAddForm,
    userIdRequired: true,
  },
  {
    id: 'asset-comments-counter',
    component: AssetCommentsCounter,
    userIdRequired: false,
  },
  {
    id: 'asset-comments',
    component: AssetComments,
    userIdRequired: true,
  },
  {
    id: 'blended-tube-page',
    component: BlendedTube,
    userIdRequired: true,
  },
  {
    id: 'custom-tagged-plate-page',
    component: CustomTaggedPlate,
  },
  {
    id: 'files-list',
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
    component: MultiStampLibrarySplitter,
  },
  {
    id: 'multi-stamp-tubes-page',
    component: MultiStampTubes,
  },
  {
    id: 'pool-xp-tube-submit-panel',
    component: PoolXPTubeSubmitPanel,
    userIdRequired: true,
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
  },
]

/**
 * Set the CSRF token in the Axios header.
 */
const setAxiosHeaderToken = (app) => {
  axios.defaults.headers.common['X-CSRF-Token'] = document
    .querySelector('meta[name="csrf-token"]')
    .getAttribute('content')
  app.config.globalProperties.$axios = axios
}

/**
 * Initialize Vue components when the DOM content is loaded.
 * For each element in the elements list, check if the element exists in the DOM.
 * If the element exists, render the Vue component with the specified props and data.
 * If a user ID is required and the user ID is missing, render an error message.
 * If the element does not exist, log a warning message.
 * The initialization logic for each element is specific to the element's id.
 */
document.addEventListener('DOMContentLoaded', () => {
  for (const { id, component, userIdRequired = false } of elements) {
    const assetElem = document.getElementById(id)
    if (!assetElem) continue
    if (id) {
      renderVueComponent(id, component, assetElem.dataset, userIdRequired)
    } else {
      console.warn(`No initialization logic defined for element with id: ${id}`)
    }
  }
})
