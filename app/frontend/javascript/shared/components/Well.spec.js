// Import the component being tested
import { shallowMount } from '@vue/test-utils'

import Well from '@/javascript/shared/components/Well.vue'

describe('Well', () => {
  // This is a workaround for the following warning:
  // [BootstrapVue warn]: tooltip - The provided target is no valid HTML element.
  const createContainer = (tag = 'div') => {
    const container = document.createElement(tag)
    document.body.appendChild(container)

    return container
  }

  const wrapperWithoutAliquot = shallowMount(Well, {
    attachTo: createContainer(),
    props: { position: 'A1', colour_index: 1 },
  })

  it('renders a well', () => {
    expect(wrapperWithoutAliquot.find('div.well').exists()).toBe(true)
  })

  it('does not render an aliquot', () => {
    expect(wrapperWithoutAliquot.find('span.aliquot').exists()).toBe(false)
  })

  const wrapperWithAliquot = shallowMount(Well, {
    attachTo: createContainer(),
    props: {
      position: 'A1',
      colour_index: 2,
      tagMapIds: [10],
      validity: { valid: true, message: '' },
    },
  })

  it('renders a well with an aliquot', () => {
    expect(wrapperWithAliquot.find('div.aliquot').exists()).toBe(true)
  })

  it('colours the aliquot', () => {
    expect(wrapperWithAliquot.find('div.aliquot.colour-2').exists()).toBe(true)
  })

  it('emits a well clicked event', () => {
    expect(wrapperWithAliquot.find('span').exists()).toBe(true)

    const input = wrapperWithAliquot.find('span')
    input.trigger('click')
    const emitted = wrapperWithAliquot.emitted()

    expect(emitted.onwellclicked.length).toBe(1)
    expect(emitted.onwellclicked[0]).toEqual(['A1'])
  })

  it('provides a tooltip with the well position', () => {
    expect(wrapperWithAliquot.vm.tooltipText).toEqual('A1')
  })

  it('renders a tooltip with the specified label', () => {
    const wrapperWithTooltipLabel = shallowMount(Well, {
      attachTo: createContainer(),
      props: { position: 'A1', tooltip_label: 'Test', colour_index: 1 },
    })
    expect(wrapperWithTooltipLabel.vm.tooltipText).toEqual('A1 - Test')
  })

  const wrapperWithTagMapIds = shallowMount(Well, {
    attachTo: createContainer(),
    props: { position: 'A1', colour_index: 1, tagMapIds: [5] },
  })

  it('renders a well with Tag Map Id displayed', () => {
    expect(wrapperWithTagMapIds.find('span.tag').text()).toEqual('5')
  })

  const wrapperWithPosition = shallowMount(Well, {
    attachTo: createContainer(),
    props: { position: 'B3', colour_index: 1 },
  })

  it('renders a well with tag name', () => {
    expect(wrapperWithPosition.find('div.well.B3').exists()).toBe(true)
  })

  const wrapperWithTagClash = shallowMount(Well, {
    attachTo: createContainer(),
    props: {
      position: 'A1',
      colour_index: 1,
      tagMapIds: [5],
      validity: { valid: false, message: 'Tag clash detected' },
    },
  })

  it('colours the aliquot when invalid', () => {
    expect(wrapperWithTagClash.find('div.aliquot.failed').exists()).toBe(true)
  })

  it('puts a line through the aliquot Tag Map Id when invalid', () => {
    expect(wrapperWithTagClash.find('span.tag.line-through').exists()).toBe(true)
  })

  const wrapperWithInvalidTag = shallowMount(Well, {
    attachTo: createContainer(),
    props: {
      position: 'A1',
      colour_index: 1,
      tagMapIds: [-1],
      validity: { valid: false, message: 'No tag in this well' },
    },
  })

  it('displays an x if the Tag Map Id is -1', () => {
    expect(wrapperWithInvalidTag.find('span.tag').text()).toEqual('x')
  })

  it('renders a well with multiple Tag Map Ids displayed according to the value of tagIndex', async () => {
    const wrapperWithMultipleAliquots = shallowMount(Well, {
      attachTo: createContainer(),
      props: {
        position: 'A1',
        colour_index: 1,
        tagMapIds: [1, 2, 3, 4],
        validity: { valid: true, message: '' },
      },
    })

    wrapperWithMultipleAliquots.setData({ tagIndex: 0 })
    await wrapperWithMultipleAliquots.vm.$nextTick()

    expect(wrapperWithMultipleAliquots.find('span.tag').text()).toEqual('1')

    wrapperWithMultipleAliquots.setData({ tagIndex: 1 })
    await wrapperWithMultipleAliquots.vm.$nextTick()

    expect(wrapperWithMultipleAliquots.find('span.tag').text()).toEqual('2')

    wrapperWithMultipleAliquots.setData({ tagIndex: 2 })
    await wrapperWithMultipleAliquots.vm.$nextTick()

    expect(wrapperWithMultipleAliquots.find('span.tag').text()).toEqual('3')

    wrapperWithMultipleAliquots.setData({ tagIndex: 3 })
    await wrapperWithMultipleAliquots.vm.$nextTick()

    expect(wrapperWithMultipleAliquots.find('span.tag').text()).toEqual('4')
  })
})
