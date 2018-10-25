// Import the component being tested
import { shallowMount, createLocalVue } from '@vue/test-utils'
import BootstrapVue from 'bootstrap-vue'
import QuadStamp from 'quadrant-stamp/components/QuadStamp.vue'

import MainContent from 'shared/components/MainContent.vue'
import Page from 'shared/components/Page.vue'
import Sidebar from 'shared/components/Sidebar.vue'


// create an extended `Vue` constructor
const localVue = createLocalVue()
// install plugins as normal
localVue.use(BootstrapVue)

localVue.component('lb-main-content', MainContent)
localVue.component('lb-page', Page)
localVue.component('lb-sidebar', Sidebar)

describe('QuadStamp', () => {

  const wrapperFactory = function() {
    // Not ideal using mount here, but having massive trouble
    // triggering change events on unmounted components
    return shallowMount(QuadStamp, {
      propsData: {
        targetRows: 16,
        targetColumns: 24,
        sourcePlateNumber: 4
      },
      localVue
    })
  }

  it('calculates transfers', () => {
    const api = ''
    const wrapper = wrapperFactory()

    expect(wrapper.vm.transfers).toEqual([])
  })

})
