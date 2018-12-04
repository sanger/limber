// base_vue exports a localVue instance extended with the same
// modules as the actual vue application

import { createLocalVue } from '@vue/test-utils'
// Merge tips: You want axios
//import axios from 'axios'
import BootstrapVue from 'bootstrap-vue'
import MainContent from 'shared/components/MainContent.vue'
import Page from 'shared/components/Page.vue'
import Sidebar from 'shared/components/Sidebar.vue'

// create an extended `Vue` constructor
const localVue = createLocalVue()
// install plugins as normal
localVue.use(BootstrapVue)

// Merge tips: You want axios
// localVue.prototype.$axios = axios

localVue.component('lb-main-content', MainContent)
localVue.component('lb-page', Page)
localVue.component('lb-sidebar', Sidebar)

export default localVue
