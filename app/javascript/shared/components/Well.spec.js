// Import the component being tested
import { shallowMount } from '@vue/test-utils'

import Well from 'shared/components/Well.vue'

describe('Well', () => {
  const wrapperWithoutAliquot = shallowMount(Well, { propsData: { pool_index: null } })

  it('renders a well', () => {
    expect(wrapperWithoutAliquot.find('div.well').exists()).toBe(true)
  })

  it('does not render an aliquot', () => {
    expect(wrapperWithoutAliquot.find('span.aliquot').exists()).toBe(false)
  })

  const wrapperWithAliquot = shallowMount(Well, {
    propsData: {
      position: 'A1',
      pool_index: 2,
      tagMapIds: [ 10 ],
      validity: { valid: true, message: '' }
    }
  })

  it('renders a well with an aliquot', () => {
    expect(wrapperWithAliquot.find('div.aliquot').exists()).toBe(true)
  })

  it('colours the aliquot', () => {
    expect(wrapperWithAliquot.find('div.aliquot.colour-2').exists()).toBe(true)
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

  const wrapperWithTagMapIds =  shallowMount(Well, { propsData: { pool_index: 1, tagMapIds: [ 5 ] } })

  it('renders a well with Tag Map Id displayed', () => {
    expect(wrapperWithTagMapIds.find('span.tag').text()).toBe('5')
  })

  const wrapperWithPosition =  shallowMount(Well, { propsData: { position: 'B3'} })

  it('renders a well with tag name', () => {
    expect(wrapperWithPosition.find('div.well.B3').exists()).toBe(true)
  })

  const wrapperWithTagClash = shallowMount(Well, { propsData: { pool_index: 1, tagMapIds: [ 5 ], validity: { valid: false, message: 'Tag clash detected' } } })

  it('colours the aliquot when invalid', () => {
    expect(wrapperWithTagClash.find('div.aliquot.failed').exists()).toBe(true)
  })

  it('puts a line through the aliquot Tag Map Id when invalid', () => {
    expect(wrapperWithTagClash.find('span.tag.line-through').exists()).toBe(true)
  })

  const wrapperWithInvalidTag = shallowMount(Well, { propsData: { pool_index: 1, tagMapIds: [ -1 ], validity: { valid: false, message: 'No tag in this well' } } })

  it('displays an x if the Tag Map Id is -1', () => {
    expect(wrapperWithInvalidTag.find('span.tag').text()).toBe('x')
  })

  const wrapperWithMultipleAliquots = shallowMount(Well, { propsData: { pool_index: 1, tagMapIds: [ 1,2,3,4 ], validity: { valid: true, message: '' } } })

  it('renders a well with multiple spans each with a Tag Map Id displayed', () => {
    expect(wrapperWithMultipleAliquots.findAll('span.tag').length).toBe(4)
  })
})
