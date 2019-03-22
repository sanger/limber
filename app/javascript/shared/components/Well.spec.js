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

  const wrapperWithAliquot = shallowMount(Well, {
    propsData: {
      position: 'A1',
      pool_index: 2,
      tagIndex: 10,
      validity: { valid: true, message: '' }
    }
  })

  it('renders a well with aliquot', () => {
    expect(wrapperWithAliquot.find('div.well').exists()).toBe(true)
  })

  it('renders an aliquot', () => {
    expect(wrapperWithAliquot.find('span.aliquot').exists()).toBe(true)
  })

  it('colours the aliquot', () => {
    expect(wrapperWithAliquot.find('span.aliquot.colour-2').exists()).toBe(true)
  })

  it('emits a well clicked event', () => {
    const emitted = wrapperWithAliquot.emitted()

    expect(wrapperWithAliquot.find('span').exists()).toBe(true)

    const input = wrapperWithAliquot.find('span')
    input.trigger('click')

    expect(emitted.onwellclicked.length).toBe(1)
    expect(emitted.onwellclicked[0]).toEqual(
      [ 'A1' ]
    )
  })

  const wrapperWithTagIndex =  shallowMount(Well, { propsData: { pool_index: 1, tagIndex: 5 } })

  it('renders a well with tag index displayed', () => {
    expect(wrapperWithTagIndex.find('span.aliquot').text()).toBe('5')
  })

  const wrapperWithPosition =  shallowMount(Well, { propsData: { position: 'B3'} })

  it('renders a well with tag name', () => {
    expect(wrapperWithPosition.find('div.well.B3').exists()).toBe(true)
  })

  const wrapperWithFailure = shallowMount(Well, { propsData: { pool_index: 1, validity: { valid: false, message: 'Tag clash detected' } } })

  it('colours the aliquot when invalid', () => {
    expect(wrapperWithFailure.find('span.aliquot.failed').exists()).toBe(true)
  })

  it('puts a line thtough the aliquot tag index when invalid', () => {
    expect(wrapperWithFailure.find('span.aliquot.line-through').exists()).toBe(true)
  })
})
