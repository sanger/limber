/* eslint no-console: 0 */

import Vue from 'vue'
import { BootstrapVue, BootstrapVueIcons } from 'bootstrap-vue'
import 'bootstrap/dist/css/bootstrap.css'
import 'bootstrap-vue/dist/bootstrap-vue.css'
import LabwareCustomMetadataAddForm from './components/LabwareCustomMetadataAddForm.vue'
import cookieJar from '@/javascript/shared/cookieJar.js'

Vue.use(BootstrapVue)
Vue.use(BootstrapVueIcons)

document.addEventListener('DOMContentLoaded', async () => {
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
  const assetElem = document.getElementById('labware-custom-metadata-add-form')
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
    const sequencescapeUrl = assetElem.dataset.sequencescapeUrl

    // UserId is required to make custom metadata, but will not be present in
    // older session cookies. To avoid errors or confusion, we render
    // a very basic vue component (essentially just an error message)
    // if userId is missing

    if (userId) {
      new Vue({
        el: '#labware-custom-metadata-add-form',
        render(h) {
          let labwareId = this.$el.dataset.labwareId
          let customMetadataFields = this.$el.dataset.customMetadataFields

          return h(LabwareCustomMetadataAddForm, {
            props: { labwareId, customMetadataFields, userId, sequencescapeApiUrl, sequencescapeUrl },
          })
        },
      })
    } else {
      new Vue({
        el: '#labware-custom-metadata-add-form',
        render: (h) => h('div', missingUserIdError),
      })
    }
  }
})
