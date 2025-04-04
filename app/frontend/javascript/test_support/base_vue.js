import { config } from '@vue/test-utils'
// import axios from 'axios'
// import { createBootstrap } from 'bootstrap-vue-next'
import MainContent from '@/javascript/shared/components/MainContent.vue'
import Page from '@/javascript/shared/components/Page.vue'
import Sidebar from '@/javascript/shared/components/Sidebar.vue'
// import mockApi from '@/javascript/test_support/mock_api.js'

config.global.components = {
    'LbMainContent': MainContent,
    'LbPage': Page,
    'LbSidebar': Sidebar,
}

