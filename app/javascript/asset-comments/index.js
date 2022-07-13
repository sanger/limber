/* eslint no-console: 0 */

import Vue from 'vue'
import BootstrapVue from 'bootstrap-vue'
import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'
import AssetComments from './components/AssetComments.vue'
import AssetCommentsCounter from './components/AssetCommentsCounter.vue'
import AssetCommentsAddForm from './components/AssetCommentsAddForm.vue'
import commentStoreFactory from './comment-store'
import axios from 'axios'
import cookieJar from 'shared/cookieJar'
import devourApi from 'shared/devourApi'
import resources from 'shared/resources'

Vue.use(BootstrapVue)

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
    const axiosInstance = axios.create({
      baseURL: sequencescapeApiUrl,
      timeout: 10000,
      headers: {
        Accept: 'application/vnd.api+json',
        'Content-Type': 'application/vnd.api+json',
      },
    })

    const api = devourApi({ apiUrl: sequencescapeApiUrl }, resources)

    const commentStore = commentStoreFactory(axiosInstance, api, assetElem.dataset.assetId, userId)

    new Vue({
      el: '#asset-comments',
      data: commentStore,
      render: (h) => h(AssetComments),
    })

    new Vue({
      el: '#asset-comments-counter',
      data: commentStore,
      render: (h) => h(AssetCommentsCounter),
    })

    // UserId is required to make comments, but will not be present in
    // older session cookies. To avoid errors or confusion, we render
    // a very basic vue component (essentially just an error message)
    // if userId is missing
    if (userId) {
      new Vue({
        el: '#asset-comments-add-form',
        data: commentStore,
        render(h) {
          return h(AssetCommentsAddForm, { props: this.$el.dataset })
        },
      })
    } else {
      new Vue({
        el: '#asset-comments-add-form',
        render: (h) => h('div', missingUserIdError),
      })
    }

    commentStore.refreshComments()
  }
})
