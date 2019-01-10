/* eslint no-console: 0 */

import Vue from 'vue'
import AssetComments from './components/AssetComments.vue'
import AssetCommentsCounter from './components/AssetCommentsCounter.vue'
import AssetCommentsAddForm from './components/AssetCommentsAddForm.vue'
import commentStoreFactory from './comment-store'
import ApiModule from 'shared/api'
import axios from 'axios'

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
  const assetElem = document.getElementById('asset-comments')

  if ( assetElem ) {
    /* The asset-comments element isn't on all pages. So only initialize our
    * Vue app if we actually find it */
    const plateApi = ApiModule({ baseUrl: assetElem.dataset.sequencescapeApi }).Plate
    const userId = document.cookie.match(/; user_id=([^;]+)/)[1]
    const axiosInstance = axios.create({
      baseURL: assetElem.dataset.sequencescapeApi,
      timeout: 10000,
      headers: {'Accept': 'application/vnd.api+json', 'Content-Type': 'application/vnd.api+json'}
    })
    const commentStore = commentStoreFactory(axiosInstance, plateApi, assetElem.dataset.assetId, userId)

    new Vue({
      el: '#asset-comments',
      data: commentStore,
      render: h => h(AssetComments)
    })

    new Vue({
      el: '#asset-comments-counter',
      data: commentStore,
      render: h => h(AssetCommentsCounter)
    })

    new Vue({
      el: '#asset-comments-add-form',
      data: commentStore,
      render (h) { return h(AssetCommentsAddForm, { props: this.$el.dataset }) }
    })

    commentStore.refreshComments()
  }
})
