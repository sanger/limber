/* eslint no-console: 0 */

import Vue from 'vue'
import AssetComments from './components/AssetComments.vue'
import ApiModule from 'shared/api'

console.log(ApiModule)

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
  if ( document.getElementById('asset-comments') ) {
    /* The asset-comments element isn't on all pages. So only initialize our
    * Vue app if we actually find it */
    var app = new Vue({
      el: '#asset-comments',
      render: h => h(AssetComments, { props: { comments: [
      {
        id: '1234',
        title: null,
        description: 'This is a comment wich is quite long, and provides lots of information to pay attention to because it has horrid run on scentances',
        createdAt: "2017-08-31T11:18:16+01:00",
        updatedAt: "2017-08-31T11:18:16+01:00",
        user: {
          id: '12',
          login: 'js1',
          firstName: 'John',
          lastName: 'Smith'
        }
      },
      {
        id: '12345',
        title: null,
        description: 'This is also a comment',
        createdAt: "2017-09-31T11:18:16+01:00",
        updatedAt: "2017-09-31T11:18:16+01:00",
        user: {
          id: '13',
          login: 'js2',
          firstName: 'Jane',
          lastName: 'Smythe'
        }
      }
    ] } })
    });
  }
})
