/* eslint-disable vue/one-component-per-file */
/* eslint no-console: 0 */

import { createApp, h } from 'vue'
import { createBootstrap } from 'bootstrap-vue-next'
import 'bootstrap-vue-next/dist/bootstrap-vue-next.css'
import AssetComments from './components/AssetComments.vue'
import AssetCommentsCounter from './components/AssetCommentsCounter.vue'
import AssetCommentsAddForm from './components/AssetCommentsAddForm.vue'
import commentStoreFactory from './comment-store.js'
import axios from 'axios'
import cookieJar from '@/javascript/shared/cookieJar.js'
import devourApi from '@/javascript/shared/devourApi.js'
import resources from '@/javascript/shared/resources.js'

document.addEventListener('DOMContentLoaded', () => {
  const assetElem = document.getElementById('asset-comments')
  const missingUserIdError = `
    Unfortunately Limber can't find your user id, which is required to make comments.
    Click log out and swipe in again to resolve this.
    If this problem occurs repeatedly, let us know.
  `

  if (assetElem) {
    /* The asset-comments element isn't on all pages. So only initialize our
     * Vue app if we actually find it */
    const userId = cookieJar(document.cookie).user_id
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

    const commentStore = commentStoreFactory(axiosInstance, api, assetElem.dataset.assetId, userId)

    let assetCommentsApp = createApp({
      data: commentStore,
      render: () => h(AssetComments),
    })
    assetCommentsApp.use(createBootstrap())
    assetCommentsApp.mount('#asset-comments')
    let assetCommentsCounterApp = createApp({
      data: commentStore,
      render: () => h(AssetCommentsCounter),
    })
    assetCommentsCounterApp.use(createBootstrap())
    assetCommentsCounterApp.mount('#asset-comments-counter')
    // UserId is required to make comments, but will not be present in
    // older session cookies. To avoid errors or confusion, we render
    // a very basic vue component (essentially just an error message)
    // if userId is missing
    if (userId) {
      let assetCommentsAddFormApp = createApp({
        data: commentStore,
        render() {
          return h(AssetCommentsAddForm, { props: this.$el.dataset })
        },
      })
      assetCommentsAddFormApp.use(createBootstrap())
      assetCommentsAddFormApp.mount('#asset-comments-add-form')
    } else {
      let missingUserIdErrorApp = createApp({
        render: h('div', missingUserIdError),
      })
      missingUserIdErrorApp.use(createBootstrap())
      missingUserIdErrorApp.mount('#asset-comments-add-form')
    }

    commentStore.refreshComments()
  }
})
