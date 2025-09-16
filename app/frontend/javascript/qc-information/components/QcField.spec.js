// Import the component being tested
import { mount } from '@vue/test-utils'

import QcField from './QcField.vue'
// Here are some Jasmine 2.0 tests, though you can
// use any test runner / assertion library combo you prefer
describe('QcField', () => {
  const wrapperFactory = function () {
    return mount(QcField, {
      props: {
        name: 'volume',
        units: 'ul',
        defaultAssayType: 'One',
        assayTypes: ['One', 'Two'],
        assetUuid: 'uuid',
      },
    })
  }

  // Inspect the raw component options
  it('renders a legend with the name', () => {
    let wrapper = wrapperFactory()

    expect(wrapper.find('legend').exists()).toBe(true)
    expect(wrapper.find('legend').text()).toBe('Volume')
  })

  it('renders the units', () => {
    let wrapper = wrapperFactory()

    expect(wrapper.find('.input-group-text').exists()).toBe(true)
    expect(wrapper.find('.input-group-text').text()).toBe('ul')
  })

  it('renders possible assay types', () => {
    let wrapper = wrapperFactory()

    expect(wrapper.find('select').exists()).toBe(true)
    expect(wrapper.find('select').findAll('option').at(0).text()).toBe('One')
    expect(wrapper.find('select').findAll('option').at(1).text()).toBe('Two')
  })

  it('updates value when the value input is filled in', () => {
    let wrapper = wrapperFactory()
    wrapper.find('input').element.value = '1.5'
    wrapper.find('input').trigger('input')

    expect(wrapper.vm.value).toBe('1.5')
  })

  it('updates assayType when assayType is selected', async () => {
    let wrapper = wrapperFactory()
    wrapper.find('select').element.value = 'Two'
    await wrapper.find('select').trigger('change')

    expect(wrapper.vm.assayType).toBe('Two')
  })

  it('emits nicely formatted quant assay objects', async () => {
    let wrapper = wrapperFactory()
    await wrapper.find('input').setValue('1.5')
    await wrapper.find('select').setValue('Two')

    expect(wrapper.emitted().change).toEqual([
      [
        {
          value: '1.5',
          assay_type: 'One',
          units: 'ul',
          key: 'volume',
          assay_version: 'manual',
          uuid: 'uuid',
        },
      ],
      [
        {
          value: '1.5',
          assay_type: 'Two',
          units: 'ul',
          key: 'volume',
          assay_version: 'manual',
          uuid: 'uuid',
        },
      ],
    ])
  })
})
