/* eslint no-console: 0 */

import Vue from 'vue'
import PrintFriendly from './components/PrintFriendly'
import VueHtmlToPaper from 'vue-html-to-paper';

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
  if (document.getElementById('testing')) {
    /* The testing element isn't on all pages. So only initialize our
    * Vue app if we actually find it */
    const options = {
      name: '_blank',
      specs: [
        'fullscreen=yes',
        'titlebar=yes',
        'scrollbars=yes'
      ],
      styles: [
        'https://stackpath.bootstrapcdn.com/bootstrap/4.4.1/css/bootstrap.min.css'
      ]
    }

    Vue.use(VueHtmlToPaper, options);
    new Vue({
      el: '#testing',
      // data: commentStore,
      render (h) { return h(PrintFriendly, { props: this.$el.dataset }) }
    })
  }
})
