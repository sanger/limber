// Import the component being tested
import { shallowMount } from '@vue/test-utils'

import Well from 'shared/components/Well.vue'

describe('Well', () => {
  const wrapper = shallowMount(Well, { propsData: { pool_index: null } })

  it('renders a well', () => {
    expect(wrapper.find('div.well').exists()).toBe(true)
  })

  it('does not render an aliquot', () => {
    expect(wrapper.find('span.aliquot').exists()).toBe(false)
  })

  const wrapperWithAliquot = shallowMount(Well, { propsData: { pool_index: 2 } })

  it('renders a well with aliquot', () => {
    expect(wrapperWithAliquot.find('div.well').exists()).toBe(true)
  })

  it('renders an aliquot', () => {
    expect(wrapperWithAliquot.find('span.aliquot').exists()).toBe(true)
  })

  it('colours the aliquot', () => {
    expect(wrapperWithAliquot.find('span.aliquot.colour-2').exists()).toBe(true)
  })

  const wrapperWithTagIndex =  shallowMount(Well, { propsData: { pool_index: 1, tagIndex: '5' } })

  it('renders a well with tag index displayed', () => {
    expect(wrapperWithTagIndex.find('span.aliquot').text()).toBe('5')
  })

  const wrapperWithPosition =  shallowMount(Well, { propsData: { position: 'B3'} })

  it('renders a well with tag name', () => {
    expect(wrapperWithPosition.find('div.well.B3').exists()).toBe(true)
  })
})
