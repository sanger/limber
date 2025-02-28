// base_vue exports a localVue instance extended with the same
// modules as the actual vue application

import { createLocalVue } from '@vue/test-utils'
import axios from 'axios'
import { createBootstrap } from 'bootstrap-vue-next'
import MainContent from '@/javascript/shared/components/MainContent.vue'
import Page from '@/javascript/shared/components/Page.vue'
import Sidebar from '@/javascript/shared/components/Sidebar.vue'
import mockApi from '@/javascript/test_support/mock_api.js'

// create an extended `Vue` constructor
const localVue = createLocalVue()
// install plugins as normal]
// localVue.use(BootstrapVue)
localVue.use(createBootstrap())

localVue.prototype.$axios = axios
localVue.prototype.$api = mockApi()

localVue.component('LbMainContent', MainContent)
localVue.component('LbPage', Page)
localVue.component('LbSidebar', Sidebar)

export default localVue
