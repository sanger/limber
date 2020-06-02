// base_vue exports a localVue instance extended with the same
// modules as the actual vue application
import Vue from 'vue'
import { createLocalVue } from '@vue/test-utils'
import axios from 'axios'
import BootstrapVue from 'bootstrap-vue'
import MainContent from 'shared/components/MainContent.vue'
import Page from 'shared/components/Page.vue'
import Sidebar from 'shared/components/Sidebar.vue'
import mockApi from 'test_support/mock_api'

Vue.use(BootstrapVue)

// create an extended `Vue` constructor
const localVue = createLocalVue()
// install plugins as normal
localVue.use(BootstrapVue)

localVue.prototype.$axios = axios
localVue.prototype.$api = mockApi()

localVue.component('lb-main-content', MainContent)
localVue.component('lb-page', Page)
localVue.component('lb-sidebar', Sidebar)

export default localVue
