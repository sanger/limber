import { mount } from '@vue/test-utils'
import ManualUltimaTagLayout from './ManualUltimaTagLayout.vue'

describe('ManualUltimaTagLayout', () => {
  const makeWrapper = (props = {}) =>
    mount(ManualUltimaTagLayout, {
      props: { api: {}, ...props },
      global: {
        stubs: {
          TagSetsLookup: {
            name: 'TagSetsLookup',
            props: ['filter'],
            template: '<div />',
          },
        },
      },
    })

  it('shows the applications and primers in a table as text', async () => {
    const wrapper = makeWrapper({
      ultimaApplications: [
        { name: '10x Flex v2', uga_primer: 'UG-CE-tR1', ugb_primer: 'UG-srR2' },
        { name: 'Application <B> & C', uga_primer: null, ugb_primer: null },
      ],
    })
    const textOf = (elements) => elements.map((element) => element.text())
    const headings = textOf(wrapper.findAll('#ultima-applications th'))
    expect(headings).toEqual(['Application', 'UGA Primer', 'UGB Primer'])
    const rows = wrapper.findAll('#ultima-applications tbody tr')
    expect(rows.map((row) => textOf(row.findAll('td')))).toEqual([
      ['10x Flex v2', 'UG-CE-tR1', 'UG-srR2'],
      ['Application <B> & C', '', ''],
    ])
    expect(wrapper.find('#ultima-applications b').exists()).toBe(false)
    await wrapper.setProps({ ultimaApplications: [] })
    expect(wrapper.find('#ultima-applications').exists()).toBe(false)
  })

  it('filters tag sets by Ultima adapter type and has no scan control', () => {
    const wrapper = makeWrapper({ tagGroupAdapterTypeNameFilter: 'Ultima' })
    expect(wrapper.findComponent({ name: 'TagSetsLookup' }).props('filter')).toEqual({
      tag_group_adapter_type_name: 'Ultima',
    })
    expect(wrapper.findComponent({ name: 'LabwareScan' }).exists()).toBe(false)
  })

  it('keeps separately named versions and emits the selected groups without a plate', async () => {
    const wrapper = makeWrapper()
    const group = { uuid: 'p1', name: 'P1 primer', tags: [{ index: 1, oligo: 'ACGT' }] }
    wrapper.vm.tagSetsLookupUpdated({
      state: 'valid',
      results: {
        first: { id: 'first', name: 'Ultima P1', tag_group: { ...group, uuid: 'p1' } },
        second: { id: 'second', name: 'Ultima P2', tag_group: group },
      },
    })
    await wrapper.setData({ tagSetId: 'second' })
    wrapper.vm.tagOffsetChanged(2)
    expect(wrapper.vm.coreTagSetOptions).toHaveLength(2)
    expect(wrapper.emitted('tagparamsupdated').at(-1)[0]).toMatchObject({
      tagPlate: null,
      tag1Group: group,
      offsetTagsBy: 2,
      walkingBy: 'manual by plate',
      direction: 'column',
    })
    await wrapper.setData({ tagSetId: null })
    expect(wrapper.vm.tag1Group.tags).toEqual([])
  })

  it('lists matching API tag sets in config order and selects their tag data by id', async () => {
    const wrapper = makeWrapper({ allowedTagSetNames: ['Ultima P2', 'Ultima P1'] })
    expect(wrapper.findComponent({ name: 'TagSetsLookup' }).exists()).toBe(true)
    expect(wrapper.vm.tagSetOptions).toEqual([{ value: null, text: 'Please select a Tagset...' }])
    expect(wrapper.find('dl').exists()).toBe(false)

    const tagGroup = { uuid: 'p1', name: 'P1', tags: [{ index: 1, oligo: 'ACGT' }] }
    wrapper.findComponent({ name: 'TagSetsLookup' }).vm.$emit('change', {
      state: 'valid',
      results: {
        first: { id: 'first', name: 'Ultima P1', tag_group: tagGroup },
        second: { id: 'second', name: 'Ultima P2', tag_group: { ...tagGroup, uuid: 'p2' } },
        third: { id: 'third', name: 'Unconfigured tag set', tag_group: { ...tagGroup, uuid: 'other' } },
      },
    })
    await wrapper.vm.$nextTick()
    expect(wrapper.vm.tagSetOptions).toEqual([
      { value: null, text: 'Please select a Tagset...' },
      { value: 'second', text: 'Ultima P2' },
      { value: 'first', text: 'Ultima P1' },
    ])

    await wrapper.find('#ultima_tag_set').setValue('first')
    expect(wrapper.vm.tagSetId).toBe('first')
    expect(wrapper.emitted('tagparamsupdated').at(-1)[0]).toMatchObject({
      tag1Group: tagGroup,
      tag2Group: { uuid: null, tags: [] },
    })

    await wrapper.setProps({ allowedTagSetNames: [] })
    expect(wrapper.vm.coreTagSetOptions).toEqual([])
    await wrapper.setProps({ allowedTagSetNames: ['Missing tag set'] })
    expect(wrapper.vm.coreTagSetOptions).toEqual([])
    await wrapper.setProps({ allowedTagSetNames: null })
    expect(wrapper.vm.coreTagSetOptions).toEqual([
      { value: 'first', text: 'Ultima P1' },
      { value: 'second', text: 'Ultima P2' },
      { value: 'third', text: 'Unconfigured tag set' },
    ])
  })
  it('does not filter tag sets by adapter type when none is configured', () => {
    const wrapper = makeWrapper({ tagGroupAdapterTypeNameFilter: '' })
    expect(wrapper.findComponent({ name: 'TagSetsLookup' }).props('filter')).toEqual({})
  })

  it('clears selected tag data when lookup becomes invalid after filtering out configured sets', async () => {
    const wrapper = makeWrapper({ allowedTagSetNames: ['Ultima P1'] })
    const tagGroup = { uuid: 'p1', name: 'P1', tags: [{ index: 1, oligo: 'ACGT' }] }

    wrapper.findComponent({ name: 'TagSetsLookup' }).vm.$emit('change', {
      state: 'valid',
      results: {
        first: { id: 'first', name: 'Ultima P1', tag_group: tagGroup },
      },
    })
    await wrapper.vm.$nextTick()
    await wrapper.find('#ultima_tag_set').setValue('first')

    await wrapper.setProps({ allowedTagSetNames: ['Missing tag set'] })
    expect(wrapper.vm.coreTagSetOptions).toEqual([])

    wrapper.findComponent({ name: 'TagSetsLookup' }).vm.$emit('change', { state: 'invalid' })
    expect(wrapper.emitted('tagparamsupdated').at(-1)[0].tag1Group.tags).toEqual([])
  })
})
